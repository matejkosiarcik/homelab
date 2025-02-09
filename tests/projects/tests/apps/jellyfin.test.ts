import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { getEnv } from '../../../utils/utils';
import { apps } from '../../../utils/apps';
import { createHttpToHttpsRedirectTests, createProxyStatusTests, createTcpTest } from '../../../utils/tests';

test.describe(apps.jellyfin.title, () => {
    for (const instance of apps.jellyfin.instances) {
        test.describe(instance.title, () => {
            for (const port of [80, 443, 8096]) {
                createTcpTest(instance.url, port);
            }

            createHttpToHttpsRedirectTests(instance.url);
            createProxyStatusTests(instance.url);

            const users = [
                {
                    username: 'admin',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                }
            ];
            for (const variant of users) {
                if (!variant.random) {
                    test(`UI: Successful login - User ${variant.username}`, async ({ page }) => {
                        await page.goto(instance.url);
                        await page.waitForURL(/\/login\.html(?:\?.*)?$/);
                        await page.locator('input#txtManualName').fill(variant.username);
                        await page.locator('input#txtManualPassword').fill(getEnv(instance.url, `${variant.username.toUpperCase()}_PASSWORD`));
                        await page.locator('button[type=submit]').click();
                        await page.waitForURL(`${instance.url}/web/#/home.html`);
                    });
                }

                test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(/\/login\.html(?:\?.*)?$/);
                    const originalUrl = page.url();
                    await page.locator('input#txtManualName').fill(variant.username);
                    await page.locator('input#txtManualPassword').fill(faker.string.alpha(10));
                    await page.locator('button[type=submit]').click();
                    await expect(page.locator('.toast:has-text("Invalid username or password.")')).toBeVisible();
                    expect(page.url(), 'URL should not change').toStrictEqual(originalUrl);
                });
            }

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Health endpoint', async () => {
                const response = await axios.get(`${instance.url}/health`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
                expect(response.data, 'Response body').toStrictEqual('Healthy');
            });
        });
    }
});
