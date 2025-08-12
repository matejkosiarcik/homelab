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

            test('UI: Successful login - User admin', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/login`);
                await page.locator('input[autocomplete="username"]').fill('test');
                await page.locator('form input[autocomplete="current-password"]').fill(getEnv(instance.url, 'TEST_PASSWORD'));
                await page.locator('ion-button[type="submit"]:has-text("Login")').click();
                await page.waitForURL(`${instance.url}/items/list/`);
                await expect(page.locator('button ion-icon.close-icon')).toBeVisible();
            });

            test('UI: Unsuccessful login - Random user', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/login`);
                await page.locator('input[autocomplete="username"]').fill(faker.string.alpha(10));
                await page.locator('form input[autocomplete="current-password"]').fill(faker.string.alpha(10));
                await page.locator('ion-button[type="submit"]:has-text("Login")').click();
                await page.waitForSelector('ion-text:has-text("Invalid Authentication")', { timeout: 10_000 });
                await expect(page).toHaveURL(`${instance.url}/login`);
            });
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
