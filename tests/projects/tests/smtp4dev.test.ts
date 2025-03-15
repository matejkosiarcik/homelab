import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps.smtp4dev.title, () => {
    for (const instance of apps.smtp4dev.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [25, 80, 443]);

            test('UI: Open', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('#tab-messages')).toBeVisible({ timeout: 5000 });
            });
        });
    }
});
