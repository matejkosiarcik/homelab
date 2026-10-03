import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '#/utils/apps.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '#/utils/tests.ts';
import { getEnv } from '#/utils/utils.ts';

const app = apps.dozzle;
const agentApp = apps['dozzle-agent'];

test.describe(app.title, () => {
    for (const instance of app.instances) {
        if ('enabled' in instance && instance.enabled === false) {
            test.skip(`Instance ${app.title} ${instance.title} is disabled`, () => {});
            continue;
        }

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
                    username: 'homelab-test',
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
                    username: 'homelab-test',
                },
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

test.describe(agentApp.title, () => {
    for (const instance of agentApp.instances) {
        if ('enabled' in instance && instance.enabled === false) {
            test.skip(`Instance ${agentApp.title} ${instance.title} is disabled`, () => {});
            continue;
        }

        test.describe(instance.title, () => {
            createTcpTests(instance.url, 7007);
        });
    }
});
