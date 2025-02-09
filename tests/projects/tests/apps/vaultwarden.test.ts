import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { getEnv } from '../../../utils/utils';
import { apps } from '../../../utils/apps';

test.describe(apps['vaultwarden'].title, () => {
    for (const instance of apps['vaultwarden'].instances) {
        test.describe(instance.title, () => {
            const users = [
                {
                    username: 'admin',
                    email: 'admin@vaultwarden.home',
                },
                {
                    username: 'homelab',
                    email: 'homelab@vaultwarden.home',
                },
                {
                    username: faker.string.alpha(10),
                    email: `${faker.string.alpha(10)}@vaultwarden.home`,
                    random: true,
                }
            ];
            for (const variant of users) {
                if (!variant.random) {
                    test(`UI: Successful login - User ${variant.username}`, async ({ page }) => {
                        await page.goto(instance.url);
                        await page.waitForURL(`${instance.url}/#/login`);
                        await page.locator('app-login input[type="email"]').waitFor({ state: 'visible', timeout: 6000 });
                        await page.locator('app-login input[type="email"]').fill(variant.email);
                        await page.locator('app-login button:has-text("Continue")').click();
                        await page.locator('app-login input[type="password"]').waitFor({ state: 'visible', timeout: 2000 });
                        await page.locator('app-login input[type="password"]').fill(getEnv(instance.url, `${variant.username.toUpperCase()}_PASSWORD`));
                        await page.locator('app-login button:has-text("Log in with master password")').click();
                        await page.waitForURL(`${instance.url}/#/vault`);
                    });
                }

                test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/#/login`);
                    await page.locator('app-login input[type="email"]').waitFor({ state: 'visible', timeout: 6000 });
                    const originalUrl = page.url();
                    await page.locator('app-login input[type="email"]').fill(variant.email);
                    await page.locator('app-login button:has-text("Continue")').click();
                    await page.locator('app-login input[type="password"]').waitFor({ state: 'visible', timeout: 2000 });
                    await page.locator('app-login input[type="password"]').fill(faker.string.alpha(10));
                    await page.locator('app-login button:has-text("Log in with master password")').click();
                    await expect(page.locator('.toast-container:has-text("Username or password is incorrect.")')).toBeVisible();
                    expect(page.url(), 'URL should not change').toStrictEqual(originalUrl);
                });
            }

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
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
