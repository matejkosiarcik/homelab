import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createTcpTest } from '../../utils/tests';

test.describe(apps.openspeedtest.title, () => {
    for (const instance of apps.openspeedtest.instances) {
        test.describe(instance.title, () => {
            // NOTE: HTTP->HTTPS not tested because redirect is disable because of speed variance
            // Proxy tests are skipped, because openspeedtest has no proxy
            createApiRootTest(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

            test('UI: Open', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('#OpenSpeedtest')).toBeVisible({ timeout: 5000 });
            });
        });
    }
});
