import https from 'node:https';
import axios from 'axios';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createProxyTests, createTcpTest } from '../../utils/tests';

test.describe(apps.openspeedtest.title, () => {
    for (const instance of apps.openspeedtest.instances) {
        test.describe(instance.title, () => {
            // NOTE: HTTP->HTTPS not tested because redirect is disable because of speed variance
            createProxyTests(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('UI: Open', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('#OpenSpeedtest')).toBeVisible({ timeout: 5000 });
            });
        });
    }
});
