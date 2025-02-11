import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createProxyStatusTests, createTcpTest } from '../../utils/tests';

test.describe(apps['vaultwarden'].title, () => {
    for (const instance of apps['vaultwarden'].instances) {
        test.describe(instance.title, () => {
            // TODO: Add test for HTTP->HTTPS redirects after real Let's Encrypt certificates
            createProxyStatusTests(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

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

            test('UI: Successful login - Superadmin', async ({ page }) => {
                await page.goto(`${instance.url}/admin`);
                await page.locator('form input[type="password"][name="token"]').waitFor({ state: 'visible', timeout: 6000 });
                await page.locator('form input[type="password"][name="token"]').fill(getEnv(instance.url, 'SUPERADMIN_PASSWORD'));
                await page.locator('form button:has-text("Enter")').click({ timeout: 10_000 });
                await expect(page.locator('a[href="/admin/logout"]').first()).toBeVisible({ timeout: 10_000 });
            });

            // NOTE: Unsuccessful Superadmin login skipped because of application throttling bad attempts and locking the account temporarily
        });
    }
});
