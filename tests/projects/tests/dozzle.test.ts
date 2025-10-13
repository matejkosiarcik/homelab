import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { getEnv } from '../../utils/utils';

test.describe(apps.dozzle.title, () => {
    for (const instance of apps.dozzle.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            const validUsers = [
                {
                    username: 'admin',
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful login - User ${user.username}`, async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/login?redirectUrl=/`);
                await page.locator('form input[name="username"]').fill(user.username);
                await page.locator('form input[name="password"]').fill(getEnv(instance.url, `${user.username}_PASSWORD`));
                await page.locator('form button[type="submit"]:has-text("Login")').click();
                await page.waitForURL(instance.url);
                await expect(page.locator('a[href^="/container/"]').first()).toBeVisible();
                });
            }

            const invalidUsers = [
                {
                    username: faker.string.alpha(10),
                    random: true,
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful login - ${user.random ? 'Random user' : `User ${user.username}`}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/login?redirectUrl=/`);
                    await page.locator('form input[name="username"]').fill(user.username);
                    await page.locator('form input[name="password"]').fill(faker.string.alpha(10));
                    await page.locator('form button[type="submit"]:has-text("Login")').click();
                    await page.waitForSelector('.text-error:has-text("Username or password are not valid")', { timeout: 10_000 });
                    await expect(page).toHaveURL(`${instance.url}/login?redirectUrl=/`);
                });
            }
        });
    }
});

test.describe(apps['dozzle-agent'].title, () => {
    for (const instance of apps['dozzle-agent'].instances) {
        test.describe(instance.title, () => {
            createTcpTests(instance.url, 7007);
        });
    }
});
