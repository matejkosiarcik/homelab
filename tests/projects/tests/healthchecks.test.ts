import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { axios, getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps.healthchecks.title, () => {
    for (const instance of apps.healthchecks.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            test('API: Status endpoint', async () => {
                const response = await axios.get(`${instance.url}/api/v3/status`);
                expect(response.status, 'Response Status').toStrictEqual(200);
                expect(response.data, 'Response body').toStrictEqual('OK');
            });

            const users = [
                {
                    username: 'admin',
                    email: 'admin@healthchecks.home.matejkosiarcik.com',
                },
                {
                    username: faker.string.alpha(10),
                    email: `${faker.string.alpha(8)}@healthchecks.home.matejkosiarcik.com`,
                    random: true,
                }
            ];
            for (const variant of users) {
                if (!variant.random) {
                    test(`UI: Successful login - User ${variant.username}`, async ({ page }) => {
                        await page.goto(instance.url);
                        await page.waitForURL(/\/accounts\/login\/?$/);
                        await page.locator('input[name="email"]').fill(variant.email);
                        await page.locator('input[name="password"]').fill(getEnv(instance.url, `${variant.username}_PASSWORD`));
                        await page.locator('button[type="submit"]:has-text("Log In")').click({ timeout: 10_000 });
                        await page.waitForURL(/\/projects\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/checks\/?$/);
                        await expect(page.locator('table#checks-table .checks-row').first()).toBeVisible();
                    });
                }

                // NOTE: Only single negative test because of rate limits
                if (variant.random) {
                    test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                        await page.goto(instance.url);
                        await page.waitForURL(/\/accounts\/login\/?$/);
                        const originalUrl = page.url();
                        await page.locator('input[name="email"]').fill(variant.email);
                        await page.locator('input[name="password"]').fill(faker.string.alpha(10));
                        await page.locator('button[type="submit"]:has-text("Log In")').click({ timeout: 10_000 });
                        await page.waitForURL(/\/accounts\/login\/?$/);
                        await expect(page.locator('.text-danger:has-text("Incorrect email or password.")')).toBeVisible();
                        await expect(page, 'URL should not change').toHaveURL(originalUrl);
                    });
                }
            }
        });
    }
});
