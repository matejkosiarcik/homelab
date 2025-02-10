import https from 'node:https';
import axios from 'axios';
import { expect, test } from '@playwright/test';
import { faker } from '@faker-js/faker';
import { apps } from '../../../utils/apps';
import { createHttpToHttpsRedirectTests, createProxyStatusTests, createTcpTest } from '../../../utils/tests';
import { getEnv } from '../../../utils/utils';

test.describe(apps.changedetection.title, () => {
    for (const instance of apps.changedetection.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyStatusTests(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

            test('UI: Successful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/login?next=/`);
                await page.locator('form input[type="password"][name="password"]').fill(getEnv(instance.url, 'PASSWORD'));
                await page.locator('form button[type="submit"]:has-text("Login")').click();
                await page.waitForURL(instance.url);
                await page.goto(`${instance.url}/settings#general`)
                await expect(page.url()).toStrictEqual(`${instance.url}/settings#general`);
            });

            test('UI: Unsuccessful login', async ({ page }) => {
                await page.goto(`${instance.url}/login`);
                await page.locator('form input[type="password"][name="password"]').fill(faker.string.alpha(10));
                await page.locator('form button[type="submit"]:has-text("Login")').click();
                await page.waitForSelector('.error:has-text("Incorrect password")', { timeout: 10_000 });
                expect(page.url()).toStrictEqual(`${instance.url}/login`);
            });

            test('API: Root', async () => {
                const response = await axios.get(instance.url, {
                    httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                    maxRedirects: 999,
                    validateStatus: () => true
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });
        });
    }
});
