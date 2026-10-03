import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '#/utils/apps.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '#/utils/tests.ts';
import { getEnv } from '#/utils/utils.ts';

const app = apps.changedetection;

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

            test('UI: Successful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/login?redirect=/`);
                await page.locator('form input[type="password"][name="password"]').fill(getEnv(instance.url, 'ADMIN_PASSWORD'));
                await page.locator('form button[type="submit"]:has-text("Login")').click({ timeout: 5000 });
                await page.waitForURL(instance.url);
                await expect(page.locator('#new-watch-form')).toBeVisible();
                await expect(page.locator('table.watch-table td.last-checked').first()).toBeVisible();
                await page.goto(`${instance.url}/settings#general`);
                await expect(page).toHaveURL(`${instance.url}/settings#general`);
            });

            test('UI: Unsuccessful login', async ({ page }) => {
                await page.goto(`${instance.url}/login`);
                await page.locator('form input[type="password"][name="password"]').fill(faker.string.alpha(10));
                await page.locator('form button[type="submit"]:has-text("Login")').click({ timeout: 5000 });
                await page.waitForSelector('.error:has-text("Incorrect password")', { timeout: 10_000 });
                await expect(page, 'URL should not change').toHaveURL(`${instance.url}/login?redirect=/`);
            });
        });
    }
});
