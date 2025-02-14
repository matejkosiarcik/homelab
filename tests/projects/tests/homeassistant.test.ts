import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createHttpToHttpsRedirectTests, createProxyStatusTests, createTcpTest } from '../../utils/tests';

test.describe(apps['home-assistant'].title, () => {
    for (const instance of apps['home-assistant'].instances) {
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

            const prometheusVariants = [
                {
                    title: 'no token',
                    auth: undefined as unknown as { username: string, password: string },
                    status: 401,
                },
                {
                    title: 'wrong token',
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

            test('API: Prometheus metrics content', async () => {
                const response = await axios.get(`${instance.url}/api/prometheus`, {
                    headers: { Authorization: `Bearer ${getEnv(instance.url, 'PROMETHEUS_BEARER_TOKEN')}` },
                    maxRedirects: 999,
                    validateStatus: () => true,
                    httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
                const content = response.data as string;
                const lines = content.split('\n');
                expect(lines.find((el) => el.startsWith('python_info'))).toBeDefined();
                expect(lines.find((el) => el.startsWith('homeassistant_state_change_total'))).toBeDefined();
                expect(lines.find((el) => el.startsWith('homeassistant_entity_available'))).toBeDefined();
                expect(lines.find((el) => el.startsWith('homeassistant_last_updated_time_seconds'))).toBeDefined();
            });

            const users = [
                {
                    username: 'admin',
                },
                {
                    username: 'homepage',
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
                        await page.waitForURL(/\/auth\/authorize(?:\?.*)?$/);
                        await page.locator('input[name="username"]').fill(variant.username);
                        await page.locator('input[name="password"]').fill(getEnv(instance.url, `${variant.username}_PASSWORD`));
                        await page.locator('button#button').click();
                        await page.waitForURL(`${instance.url}/lovelace/0`);
                        await expect(page.locator('home-assistant')).toBeVisible();
                        await expect(page.locator('ha-sidebar')).toBeVisible();
                        await expect(page.locator('ha-panel-lovelace')).toBeVisible();
                    });
                }

                test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(/\/auth\/authorize(?:\?.*)?$/);
                    const originalUrl = page.url();
                    await page.locator('input[name="username"]').fill(variant.username);
                    await page.locator('input[name="password"]').fill(faker.string.alpha(10));
                    await page.locator('button#button').click();
                    await expect(page.locator('ha-alert[alert-type="error"]:has-text("Invalid username or password")')).toBeVisible();
                    expect(page.url(), 'URL should not change').toStrictEqual(originalUrl);
                });
            }
        });
    }
});
