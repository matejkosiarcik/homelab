import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { getEnv } from '../../../utils/utils';
import { apps } from '../../../utils/apps';

test.describe(apps.healthchecks.title, () => {
    for (const instance of apps.healthchecks.instances) {
        test.describe(instance.title, () => {
            test('UI: Successful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(/\/accounts\/login\/?$/);
                await page.locator('input[name="email"]').fill('admin@healthchecks.home');
                await page.locator('input[name="password"]').fill(getEnv(instance.url, 'PASSWORD'));
                await page.locator('button[type=submit]:has-text("Log In")').click({ timeout: 10_000 });
                await page.waitForURL(/\/projects\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/checks\/?$/);
            });

            test('UI: Unsuccessful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(/\/accounts\/login\/?$/);
                const originalUrl = page.url();
                await page.locator('input[name="email"]').fill('admin@healthchecks.home');
                await page.locator('input[name="password"]').fill(faker.string.alpha(10));
                await page.locator('button[type=submit]:has-text("Log In")').click({ timeout: 10_000 });
                await page.waitForURL(/\/accounts\/login\/?$/);
                await expect(page.locator('.text-danger:has-text("Incorrect email or password.")')).toBeVisible();
                expect(page.url(), 'URL should not change').toStrictEqual(originalUrl);
            });

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Status endpoint', async () => {
                const response = await axios.get(`${instance.url}/api/v3/status`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
                expect(response.data, 'Response body').toStrictEqual('OK');
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
