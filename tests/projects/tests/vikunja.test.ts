import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { faker } from '@faker-js/faker';
import { getEnv } from '../../utils/utils';

test.describe(apps.vikunja.title, () => {
    for (const instance of apps.vikunja.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);
            // TODO: Prometheus tests

            const validUsers = [
                {
                    username: 'test',
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful login - User ${user.username}`, async ({ page }) => {
                    // Load page
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/login`);
                    await expect(page.locator('form#loginform')).toBeVisible();

                    // Fill in form
                    await page.locator('form#loginform input#username').fill(user.username);
                    await page.locator('form#loginform input#password').fill(getEnv(instance.url, `${user.username}_PASSWORD`));
                    await page.locator('form#loginform button[type="button"]:has-text("Login")').click();

                    // Verify login
                    await expect(page.locator('aside li .project-menu-title:has-text("Inbox")')).toBeVisible();
                });
            }

            const invalidUsers = [
                {
                    title: 'User homelab-test',
                    username: 'homelab-test',
                },
                {
                    title: 'Random user',
                    username: faker.string.alpha(10),
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful login - ${user.title}`, async ({ page }) => {
                    // Load page
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/login`);
                    const originalUrl = page.url();
                    await expect(page.locator('form#loginform')).toBeVisible();

                    // Fill in form
                    await page.locator('form#loginform input#username').fill(user.username);
                    await page.locator('form#loginform input#password').fill(faker.string.alphanumeric(10));
                    await page.locator('form#loginform button[type="button"]:has-text("Login")').click();

                    // Verify fail
                    await expect(page.locator('.message:has-text("Wrong username or password.")')).toBeVisible();
                    await expect(page).toHaveURL(originalUrl);
                });
            }
        });
    }
});
