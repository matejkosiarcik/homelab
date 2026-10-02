import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps.openspeedtest.title, () => {
    for (const instance of apps.openspeedtest.instances) {
        if ('enabled' in instance && instance.enabled === false) {
            test.skip(`Instance ${apps.openspeedtest.title} ${instance.title} is disabled`, () => {});
            continue;
        }

        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url, { redirect: false });
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);
            createApiRootTest(instance.url);

            test('UI: Open', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('#OpenSpeedtest')).toBeVisible({ timeout: 5000 });
            });
        });
    }
});
