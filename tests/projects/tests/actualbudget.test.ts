import https from 'node:https';
import os from 'node:os';
import fs from 'node:fs/promises';
import axios from 'axios';
import actualbudgetApi from '@actual-app/api';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createHttpToHttpsRedirectTests, createProxyStatusTests, createTcpTest } from '../../utils/tests';
import { getEnv } from '../../utils/utils';

test.describe(apps.actualbudget.title, () => {
    for (const instance of apps.actualbudget.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyStatusTests(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('UI: Successful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/login`);
                await page.locator('input[type="password"][placeholder="Password"]').fill(getEnv(instance.url, 'PASSWORD'));
                await page.locator('button[type="button"]:has-text("Sign in")').click();
                await page.waitForURL(instance.url);
                await expect(page.locator('#root:has-text("Files")')).toBeVisible();
                await expect(page.locator('button:has-text("Create new file")')).toBeVisible();
            });

            test('UI: Unsuccessful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/login`);
                await page.locator('input[type="password"][placeholder="Password"]').fill(faker.string.alpha(10));
                await page.locator('button[type="button"]:has-text("Sign in")').click();
                await page.waitForSelector('text="Invalid password"', { timeout: 6000 });
                expect(page.url()).toStrictEqual(`${instance.url}/login`);
            });

            test('API: Download budget', async () => {
                const cacheDir = await fs.mkdtemp(`${os.tmpdir()}/actualbudget-`);
                const originalConsoleLog = console.log;
                const silentConsoleLog = () => {};

                try {
                    await fs.mkdir(cacheDir, { recursive: true });
                    console.log = silentConsoleLog;

                    await actualbudgetApi.init({
                        dataDir: cacheDir,
                        serverURL: instance.url,
                        password: getEnv(instance.url, 'PASSWORD'),
                    });
                    await actualbudgetApi.downloadBudget(getEnv(instance.url, 'SYNC_ID'));
                    await actualbudgetApi.sync();
                    const accounts = await actualbudgetApi.getAccounts();
                    expect(accounts, 'There should be some accounts').not.toHaveLength(0);
                    expect(accounts, 'There should be exactly 1 account').toHaveLength(1);
                    await actualbudgetApi.getTransactions(accounts[0].id, '1900-01-01', '2999-12-31');
                } finally {
                    console.log = originalConsoleLog;
                    await fs.rm(cacheDir, { recursive: true, force: true });
                }
            })
        });
    }
});
