import https from 'node:https';
import axios from 'axios';
import { expect, test } from '@playwright/test';
import { faker } from '@faker-js/faker';
import { getEnv } from '../../../utils/utils';
import { apps } from '../../../utils/apps';

test.describe(apps['home-assistant'].title, () => {
    for (const instance of apps['home-assistant'].instances) {
        test.describe(instance.title, () => {
            test('UI: Successful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(/\/auth\/authorize(?:\?.*)?$/);
                await page.locator('input[name="username"]').fill('admin');
                await page.locator('input[name="password"]').fill(getEnv(instance.url, 'PASSWORD'));
                await page.locator('button#button').click();
                await page.waitForURL(`${instance.url}/lovelace/0`);
            });

            test('UI: Unsuccessful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(/\/auth\/authorize(?:\?.*)?$/);
                const originalUrl = page.url();
                await page.locator('input[name="username"]').fill('admin');
                await page.locator('input[name="password"]').fill(faker.string.alpha(10));
                await page.locator('button#button').click();
                await expect(page.locator('ha-alert[alert-type="error"]:has-text("Invalid username or password")')).toBeVisible();
                expect(page.url(), 'URL should not change').toStrictEqual(originalUrl);
            });

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            const prometheusVariants = [
                {
                    title: 'missing credentials',
                    auth: undefined as unknown as { username: string, password: string },
                    status: 401,
                },
                {
                    title: 'wrong credentials',
                    auth: faker.internet.jwt(),
                    status: 401,
                },
                {
                    title: 'successful',
                    auth: getEnv(instance.url, 'PROMETHEUS_BEARER_TOKEN'),
                    status: 200,
                },
            ];
            for (const variant of prometheusVariants) {
                test(`API: Prometheus metrics (${variant.title})`, async () => {
                    const headers: Record<string, string> = {};
                    if (variant.auth) {
                        headers['Authorization'] = `Bearer ${variant.auth}`;
                    }

                    const response = await axios.get(`${instance.url}/api/prometheus`, {
                        headers: headers,
                        maxRedirects: 999,
                        validateStatus: () => true,
                        httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                    });
                    expect(response.status, 'Response Status').toStrictEqual(variant.status);
                });
            }

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
                    const response = await axios.get(`${instance.url}/.proxy/status`, {
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
