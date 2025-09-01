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

            test(`UI: Successful login - User test`, async ({ page }) => {
                // Load page
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/login`);
                await expect(page.locator('form#loginform')).toBeVisible();

                // Fill in form
                await page.locator('form#loginform input#username').fill('test');
                await page.locator('form#loginform input#password').fill(getEnv(instance.url, 'TEST_PASSWORD'));
                await page.locator('form#loginform button[type="button"]:has-text("Login")').click();

                // Verify login
                await expect(page.locator('aside li:has-text("Inbox") a[href="/projects/1"]')).toBeVisible();
            });

            const users = [
                {
                    username: 'test',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                }
            ];
            for (const variant of users) {
                test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    // Load page
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/login`);
                    const originalUrl = page.url();
                    await expect(page.locator('form#loginform')).toBeVisible();

                    // Fill in form
                    await page.locator('form#loginform input#username').fill('test');
                    await page.locator('form#loginform input#password').fill(getEnv(instance.url, 'TEST_PASSWORD'));
                    await page.locator('form#loginform button[type="button"]:has-text("Login")').click();

                    // Verify fail
                    await expect(page.locator('.message:has-text("Wrong username or password.")')).toBeVisible();
                    await expect(page).toHaveURL(originalUrl);
                });
            }
        });
    }
});
