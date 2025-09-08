import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { faker } from '@faker-js/faker';
import { getEnv } from '../../utils/utils';

test.describe(apps.uptimekuma.title, () => {
    for (const instance of apps.uptimekuma.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'basic', username: 'matej' });

            const validUsers = [
                {
                    username: 'matej'
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful login - User ${user.username}`, async ({ page }) => {
                    // Load page
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/dashboard`);
                    await expect(page.locator('.form-container form')).toBeVisible();
                    // await expect(PageRevealEvent.getByRole('heading', { name: 'All Messages'})).not.toBeVisible();

                    // Fill in form
                    await page.locator('form input[autocomplete="username"]').fill(user.username);
                    await page.locator('form input[type="password"]').fill(getEnv(instance.url, `${user.username}_PASSWORD`));
                    await page.locator('form button[type="submit"]:has-text("Log In")').click();

                    // Verify login
                    await expect(page.locator('.form-container form')).not.toBeVisible();
                    await expect(page.getByRole('heading', { name: 'Quick Stats'})).toBeVisible();
                });
            }

            const invalidUsers = [
                {
                    title: 'Random user',
                    username: faker.string.alpha(10),
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful login - ${user.title}`, async ({ page }) => {
                    // Load page
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/dashboard`);
                    await expect(page.locator('.form-container form')).toBeVisible();
                    await expect(page.getByRole('alert', { name: 'Incorrect username or password.' })).not.toBeVisible();

                    // Fill in form
                    await page.locator('form input[autocomplete="username"]').fill(user.username);
                    await page.locator('form input[type="password"]').fill(faker.string.alpha(10));
                    await page.locator('form button[type="submit"]:has-text("Log In")').click();

                    // Verify fail
                    await expect(page.locator('[role="alert"]:has-text("Incorrect username or password.")')).toBeVisible();
                });
            }
        });
    }
});
