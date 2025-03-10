import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createHttpToHttpsRedirectTests, createProxyTests, createTcpTest } from '../../utils/tests';
import { getEnv } from '../../utils/utils';

test.describe(apps.changedetection.title, () => {
    for (const instance of apps.changedetection.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

            test('UI: Successful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/login?next=/`);
                await page.locator('form input[type="password"][name="password"]').fill(getEnv(instance.url, 'PASSWORD'));
                await page.locator('form button[type="submit"]:has-text("Login")').click({ timeout: 5000 });
                await page.waitForURL(instance.url);
                await expect(page.locator('#new-watch-form')).toBeVisible();
                await expect(page.locator('table.watch-table td.last-checked').first()).toBeVisible();
                await page.goto(`${instance.url}/settings#general`);
                expect(page.url()).toStrictEqual(`${instance.url}/settings#general`);
            });

            test('UI: Unsuccessful login', async ({ page }) => {
                await page.goto(`${instance.url}/login`);
                await page.locator('form input[type="password"][name="password"]').fill(faker.string.alpha(10));
                await page.locator('form button[type="submit"]:has-text("Login")').click({ timeout: 5000 });
                await page.waitForSelector('.error:has-text("Incorrect password")', { timeout: 10_000 });
                expect(page.url()).toStrictEqual(`${instance.url}/login`);
            });
        });
    }
});
