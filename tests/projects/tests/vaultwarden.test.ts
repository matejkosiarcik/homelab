import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps['vaultwarden'].title, () => {
    for (const instance of apps['vaultwarden'].instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            test('UI: Successful login - User test', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/#/login`);
                await page.locator('form input[type="email"]').waitFor({ state: 'visible', timeout: 6000 });
                await page.locator('form input[type="email"]').fill('test@vaultwarden.matejhome.com');
                await page.locator('form button:has-text("Continue")').click();
                await page.locator('form input[type="password"]').waitFor({ state: 'visible', timeout: 2000 });
                await page.locator('form input[type="password"]').fill(getEnv(instance.url, 'TEST_PASSWORD'));
                await page.locator('form button:has-text("Log in with master password")').click();
                await page.waitForURL(`${instance.url}/#/vault`);
                await page.locator('app-vault').waitFor();
            });

            test('UI: Unsuccessful login - Random user', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/#/login`);
                await page.locator('form input[type="email"]').waitFor({ state: 'visible', timeout: 6000 });
                const originalUrl = page.url();
                await page.locator('form input[type="email"]').fill(`${faker.string.alpha(8)}@vaultwarden.matejhome.com`);
                await page.locator('form button:has-text("Continue")').click();
                await page.locator('form input[type="password"]').waitFor({ state: 'visible', timeout: 2000 });
                await page.locator('form input[type="password"]').fill(faker.string.alpha(10));
                await page.locator('form button:has-text("Log in with master password")').click();
                await expect(page.locator('bit-error:has-text("Invalid master password")')).toBeVisible();
                await expect(page, 'URL should not change').toHaveURL(originalUrl);
            });
        });
    }
});
