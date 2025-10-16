import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { getEnv } from '../../utils/utils';

test.describe(apps.gotify.title, () => {
    for (const instance of apps.gotify.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            const validUsers = [
                {
                    username: 'matej',
                },
                {
                    username: 'homelab-viewer',
                },
                {
                    username: 'homelab-test',
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful login - User ${user.username}`, async ({ page }) => {
                    // Load page
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/#/login`);
                    await expect(page.locator('form#login-form')).toBeVisible();
                    await expect(page.getByRole('heading', { name: 'All Messages'})).not.toBeVisible();

                    // Fill in form
                    await page.locator('form#login-form input[autocomplete="username"]').fill( user.username);
                    await page.locator('form#login-form input[type="password"]').fill(getEnv(instance.url, `${user.username}_PASSWORD`));
                    await page.locator('form#login-form button[type="submit"]:has-text("Login")').click();

                    // Verify login
                    await page.waitForURL(`${instance.url}/#/`);
                    await expect(page.locator('form#login-form')).not.toBeVisible();
                    await expect(page.getByRole('heading', { name: 'All Messages'})).toBeVisible();
                });
            }

            const invalidUsers = [
                {
                    username: 'homelab-test',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful login - ${user.random ? 'Random user' : `User ${user.username}`}`, async ({ page }) => {
                    // Load page
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/#/login`);
                    await expect(page.locator('form#login-form')).toBeVisible();
                    await expect(page.locator('.notistack-snackbar:has-text("Login failed")')).not.toBeVisible();

                    // Fill in form
                    await page.locator('form#login-form input[autocomplete="username"]').fill(user.username);
                    await page.locator('form#login-form input[type="password"]').fill(faker.string.alpha(10));
                    await page.locator('form#login-form button[type="submit"]:has-text("Login")').click();

                    // Verify fail
                    await expect(page.locator('.notistack-snackbar:has-text("Login failed")')).toBeVisible();
                });
            }
        });
    }
});
