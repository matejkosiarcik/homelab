import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { faker } from '@faker-js/faker';
import { getEnv } from '../../utils/utils';

test.describe(apps['uptime-kuma'].title, () => {
    for (const instance of apps['uptime-kuma'].instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'basic', username: 'matej' });

            const users = [
                {
                    username: 'matej',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                }
            ];
            for (const variant of users) {
                if (!variant.random) {
                    test(`UI: Successful login - User ${variant.username}`, async ({ page }) => {
                        // Load page
                        await page.goto(instance.url);
                        await page.waitForURL(`${instance.url}/dashboard`);
                        await expect(page.locator('.form-container form')).toBeVisible();
                        // await expect(PageRevealEvent.getByRole('heading', { name: 'All Messages'})).not.toBeVisible();

                        // Fill in form
                        await page.locator('form input[autocomplete="username"]').fill(variant.username);
                        await page.locator('form input[type="password"]').fill(getEnv(instance.url, 'ADMIN_PASSWORD'));
                        await page.locator('form button[type="submit"]:has-text("Login")').click();

                        // Verify login
                        await expect(page.locator('.form-container form')).not.toBeVisible();
                        await expect(page.getByRole('heading', { name: 'Quick Stats'})).toBeVisible();
                    });
                }

                test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    // Load page
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/dashboard`);
                    await expect(page.locator('.form-container form')).toBeVisible();
                    await expect(page.getByRole('alert', { name: 'Incorrect username or password.' })).not.toBeVisible();

                    // Fill in form
                    await page.locator('form input[autocomplete="username"]').fill(variant.username);
                    await page.locator('form input[type="password"]').fill(faker.string.alpha(10));
                    await page.locator('form button[type="submit"]:has-text("Login")').click();

                    // Verify fail
                    await expect(page.locator('[role="alert"]:has-text("Incorrect username or password.")')).toBeVisible();
                });
            }
        });
    }
});
