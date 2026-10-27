import os from 'node:os';
import fs from 'node:fs/promises';
import actualbudgetApi from '@actual-app/api';
import { faker } from '@faker-js/faker';
import { expect, test } from '#/playwright/test.ts';
import { apps } from '#/utils/apps.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '#/utils/tests.ts';
import { getEnv } from '#/utils/utils.ts';

const app = apps.actualbudget;

test.describe(app.title, () => {
    for (const instance of app.instances) {
        if ('enabled' in instance && instance.enabled === false) {
            test.skip(`Instance ${app.title} ${instance.title} is disabled`, () => {});
            continue;
        }

        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            test('UI: Successful login', async ({ page }) => {
                await test.step('Open login', async () => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/login`);
                });

                await test.step('Login', async () => {
                    await page.locator('input[type="password"][placeholder="Password"]').fill(getEnv(instance.url, 'ADMIN_PASSWORD'));
                    await page.locator('button[type="button"]:has-text("Sign in")').click({ noWaitAfter: true });
                });

                await test.step('Validate login', async () => {
                    await page.waitForURL(instance.url);
                    await expect(page.locator('#root:has-text("Files")')).toBeVisible();
                    await expect(page.locator('button:has-text("Create new file")')).toBeVisible();
                });
            });

            test('UI: Unsuccessful login', async ({ page }) => {
                await test.step('Open login', async () => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/login`);
                });

                await test.step('Attempt login', async () => {
                    await page.locator('input[type="password"][placeholder="Password"]').fill(faker.string.alpha(10));
                    await page.locator('button[type="button"]:has-text("Sign in")').click();
                });

                await test.step('Validate login attempt', async () => {
                    await page.waitForSelector('text="Invalid password"', { timeout: 6000 });
                    await expect(page, 'URL should not change').toHaveURL(`${instance.url}/login`);
                });
            });

            test('API: Download budget', async () => {
                const cacheDir = await fs.mkdtemp(`${os.tmpdir()}/actualbudget-`);
                const originalConsoleLog = console.log;
                const silentConsoleLog = () => {};

                try {
                    await fs.mkdir(cacheDir, { recursive: true });
                    console.log = silentConsoleLog;

                    const accounts = await test.step('Connect to server', async () => {
                        await actualbudgetApi.init({
                            dataDir: cacheDir,
                            serverURL: instance.url,
                            password: getEnv(instance.url, 'ADMIN_PASSWORD'),
                        });
                        await actualbudgetApi.downloadBudget(getEnv(instance.url, 'SYNC_ID'), { password: getEnv(instance.url, 'ENCRYPTION_PASSWORD') });
                        await actualbudgetApi.sync();
                        return await actualbudgetApi.getAccounts();
                    });

                    await test.step('Validate server data', async () => {
                        expect(accounts, 'There should be some accounts').not.toHaveLength(0);
                        expect(accounts, 'There should be exactly 1 account').toHaveLength(1);
                        await actualbudgetApi.getTransactions(accounts[0].id, '1900-01-01', '2999-12-31');
                    });
                } finally {
                    await test.step('Close server connection', async () => {
                        await actualbudgetApi.shutdown();
                    });

                    await test.step('Cleanup data', async () => {
                        console.log = originalConsoleLog;
                        await fs.rm(cacheDir, { recursive: true, force: true });
                    });
                }
            })
        });
    }
});
