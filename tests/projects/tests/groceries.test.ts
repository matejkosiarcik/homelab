import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { getEnv } from '../../utils/utils';

test.describe(apps.groceries.title, () => {
    for (const instance of apps.groceries.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            const validUsers = [
                {
                    username: 'homelabtest', // Username is missing dash, because of app restrictions
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful login - User ${user.username}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/login`);
                    await page.locator('input[autocomplete="username"]').fill(user.username);
                    await page.locator('input[autocomplete="current-password"]').fill(getEnv(instance.url, `${user.username}_PASSWORD`));
                    await page.locator('ion-button[type="submit"]:has-text("Login")').click();
                    await page.waitForURL(`${instance.url}/lists`);
                    await expect(page.locator('ion-icon.sync-icon')).toBeVisible();
                });
            }

            const invalidUsers = [
                {
                    username: 'homelabtest',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful login - ${user.random ? 'Random user' : `User ${user.username}`}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/login`);
                    await page.locator('input[autocomplete="username"]').fill(user.username);
                    await page.locator('input[autocomplete="current-password"]').fill(faker.string.alpha(10));
                    await page.locator('ion-button[type="submit"]:has-text("Login")').click();
                    await page.waitForSelector('ion-text:has-text("Invalid Authentication")', { timeout: 10_000 });
                    await expect(page).toHaveURL(`${instance.url}/login`);
                });
            }
        });
    }
});
