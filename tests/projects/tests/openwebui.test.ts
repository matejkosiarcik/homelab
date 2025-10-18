import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { getEnv } from '../../utils/utils';
import { faker } from '@faker-js/faker';

test.describe(apps['openwebui'].title, () => {
    for (const instance of apps['openwebui'].instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            const validUsers = [
                {
                    email: 'matej@matejhome.com',
                },
                {
                    email: 'homelab-viewer@homelab.matejhome.com',
                },
                {
                    email: 'homelab-test@homelab.matejhome.com',
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful login - User ${user.email.split('@')[0]}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/auth?redirect=%2F`);
                    await page.locator('form input#email').fill(user.email);
                    await page.locator('form input#password').fill(getEnv(instance.url, `${user.email.split('@')[0]}_PASSWORD`));
                    await page.locator('form button[type="submit"]:has-text("Sign in")').click();
                    await page.waitForURL(`${instance.url}/`);
                    await expect(page.locator('section[aria-label*="Notifications"] [data-content]:has-text("You\'re now logged in.")')).toBeVisible();
                    await expect(page.locator('#chat-input')).toBeVisible();
                });
            }

            const invalidUsers = [
                {
                    email: 'homelab-test@homelab.matejhome.com',
                },
                {
                    email: `${faker.string.alpha(10)}@homelab.matejhome.com`,
                    random: true,
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful login - ${user.random ? 'Random user' : `User ${user.email.split('@')[0]}`}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/auth?redirect=%2F`);
                    await page.locator('form input#email').fill(user.email);
                    await page.locator('form input#password').fill(faker.string.alpha(10));
                    await page.locator('form button[type="submit"]:has-text("Sign in")').click();
                    await expect(page.locator('section[aria-label*="Notifications"] [data-content]:has-text("The email or password provided is incorrect. Please check for typos and try logging in again.")')).toBeVisible();
                });
            }

        });
    }
});
