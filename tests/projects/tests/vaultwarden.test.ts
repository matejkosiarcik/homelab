import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps['vaultwarden'].title, () => {
    for (const instance of apps['vaultwarden'].instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            const users = [
                {
                    username: 'admin',
                    email: 'admin@vaultwarden.home.matejkosiarcik.com',
                },
                {
                    username: 'homelab',
                    email: 'homelab@vaultwarden.home.matejkosiarcik.com',
                },
                {
                    username: faker.string.alpha(10),
                    email: `${faker.string.alpha(10)}@vaultwarden.home.matejkosiarcik.com`,
                    random: true,
                }
            ];
            for (const variant of users) {
                if (!variant.random) {
                    test(`UI: Successful login - User ${variant.username}`, async ({ page }) => {
                        await page.goto(instance.url);
                        await page.waitForURL(`${instance.url}/#/login`);
                        await page.locator('form input[type="email"]').waitFor({ state: 'visible', timeout: 6000 });
                        await page.locator('form input[type="email"]').fill(variant.email);
                        await page.locator('form button:has-text("Continue")').click();
                        await page.locator('form input[type="password"]').waitFor({ state: 'visible', timeout: 2000 });
                        await page.locator('form input[type="password"]').fill(getEnv(instance.url, `${variant.username}_PASSWORD`));
                        await page.locator('form button:has-text("Log in with master password")').click();
                        await page.locator('form input#bit-input-2').waitFor({ state: 'visible', timeout: 2000 });
                    });
                }

                // NOTE: Only single negative test because of rate limits
                if (variant.random) {
                    test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                        await page.goto(instance.url);
                        await page.waitForURL(`${instance.url}/#/login`);
                        await page.locator('form input[type="email"]').waitFor({ state: 'visible', timeout: 6000 });
                        const originalUrl = page.url();
                        await page.locator('form input[type="email"]').fill(variant.email);
                        await page.locator('form button:has-text("Continue")').click();
                        await page.locator('form input[type="password"]').waitFor({ state: 'visible', timeout: 2000 });
                        await page.locator('form input[type="password"]').fill(faker.string.alpha(10));
                        await page.locator('form button:has-text("Log in with master password")').click();
                        await expect(page.locator('bit-error:has-text("Invalid master password")')).toBeVisible();
                        await expect(page, 'URL should not change').toHaveURL(originalUrl);
                    });
                }
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
