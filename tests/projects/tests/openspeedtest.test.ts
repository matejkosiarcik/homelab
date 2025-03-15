import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createHttpsToHttpRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps.openspeedtest.title, () => {
    for (const instance of apps.openspeedtest.instances) {
        test.describe(instance.title, () => {
            createHttpsToHttpRedirectTests(instance.url);
            createProxyTests(instance.url, { redirect: false });
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);

            test('UI: Open', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('#OpenSpeedtest')).toBeVisible({ timeout: 5000 });
            });
        });
    }
});
