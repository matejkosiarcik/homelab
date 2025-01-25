import https from 'node:https';
import axios from 'axios';
import { expect, test } from '@playwright/test';
import { faker } from '@faker-js/faker';
import { getEnv } from '../../../utils/utils';
import { apps } from '../../../utils/apps';

test.describe.only(apps.jellyfin.title, () => {
    for (const instance of apps.jellyfin.instances) {
        test.describe(instance.title, () => {
            test('UI: Successful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(/\/login\.html(?:\?.*)?$/);
                await page.locator('input#txtManualName').fill('admin');
                await page.locator('input#txtManualPassword').fill(getEnv(instance.url, 'PASSWORD'));
                await page.locator('button[type=submit]').click();
                await page.waitForURL(`${instance.url}/web/#/home.html`);
            });

            test('UI: Unsuccessful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(/\/login\.html(?:\?.*)?$/);
                const originalUrl = page.url();
                await page.locator('input#txtManualName').fill('admin');
                await page.locator('input#txtManualPassword').fill(faker.string.alpha(10));
                await page.locator('button[type=submit]').click();
                await expect(page.locator('.toast:has-text("Invalid username or password.")')).toBeVisible();
                expect(page.url(), 'URL should not change').toStrictEqual(originalUrl);
            });

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Health endpoint', async () => {
                const response = await axios.get(`${instance.url}/health`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
                expect(response.data, 'Response body').toStrictEqual('Healthy');
            });

            const proxyStatusVariants = [
                {
                    title: 'missing credentials',
                    auth: undefined as unknown as { username: string, password: string },
                    status: 401,
                },
                {
                    title: 'wrong credentials',
                    auth: {
                        username: 'proxy-status',
                        password: faker.string.alphanumeric(10),
                    },
                    status: 401,
                },
                {
                    title: 'successful',
                    auth: {
                        username: 'proxy-status',
                        password: getEnv(instance.url, 'PROXY_STATUS_PASSWORD'),
                    },
                    status: 200,
                },
            ];
            for (const variant of proxyStatusVariants) {
                test(`API: Proxy status (${variant.title})`, async () => {
                    const response = await axios.get(`${instance.url}/.apache/status`, {
                        auth: variant.auth,
                        maxRedirects: 999,
                        validateStatus: () => true,
                        httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                    });
                    expect(response.status, 'Response Status').toStrictEqual(variant.status);
                });
            }
        });
    }
});
