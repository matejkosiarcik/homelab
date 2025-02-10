import https from 'node:https';
import axios from 'axios';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createHttpToHttpsRedirectTests, createProxyStatusTests, createTcpTest } from '../../utils/tests';
import { getEnv } from '../../utils/utils';
import { faker } from '@faker-js/faker';

test.describe(apps.actualbudget.title, () => {
    for (const instance of apps.actualbudget.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyStatusTests(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

            test('UI: Successful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/login`);
                await page.locator('input[type="password"][placeholder="Password"]').fill(getEnv(instance.url, 'PASSWORD'));
                await page.locator('button[type="button"]:has-text("Sign in")').click();
                await page.waitForURL(instance.url);
            });

            test('UI: Unsuccessful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/login`);
                await page.locator('input[type="password"][placeholder="Password"]').fill(faker.string.alpha(10));
                await page.locator('button[type="button"]:has-text("Sign in")').click();
                await page.waitForSelector('text="Invalid password"', { timeout: 6000 });
                expect(page.url()).toStrictEqual(`${instance.url}/login`);
            });


            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });
        });
    }
});
