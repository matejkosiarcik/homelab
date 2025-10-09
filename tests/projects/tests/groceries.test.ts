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

            test('UI: Successful login - User homelab-test', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/login`);
                await page.locator('input[autocomplete="username"]').fill('homelab-test'); // Username is weird, because there is a minimum length limit
                await page.locator('input[autocomplete="current-password"]').fill(getEnv(instance.url, 'HOMELAB_TEST_PASSWORD'));
                await page.locator('ion-button[type="submit"]:has-text("Login")').click();
                await page.waitForURL(`${instance.url}/lists`);
                await expect(page.locator('ion-icon.sync-icon')).toBeVisible();
            });

            test('UI: Unsuccessful login - Random user', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/login`);
                await page.locator('input[autocomplete="username"]').fill(faker.string.alpha(10));
                await page.locator('input[autocomplete="current-password"]').fill(faker.string.alpha(10));
                await page.locator('ion-button[type="submit"]:has-text("Login")').click();
                await page.waitForSelector('ion-text:has-text("Invalid Authentication")', { timeout: 10_000 });
                await expect(page).toHaveURL(`${instance.url}/login`);
            });
        });
    }
});
