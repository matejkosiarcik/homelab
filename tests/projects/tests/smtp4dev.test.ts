import https from 'node:https';
import axios from 'axios';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createHttpToHttpsRedirectTests, createProxyStatusTests, createTcpTest } from '../../utils/tests';

test.describe(apps.smtp4dev.title, () => {
    for (const instance of apps.smtp4dev.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyStatusTests(instance.url);

            for (const port of [25, 80, 443]) {
                createTcpTest(instance.url, port);
            }

            test('UI: Open', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('#tab-messages')).toBeVisible({ timeout: 5000 });
            });

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });
        });
    }
});
