import https from 'node:https';
import axios from 'axios';
import { expect, test } from '@playwright/test';
import { apps } from '../../../utils/apps';
import { createProxyStatusTests, createTcpTest } from '../../../utils/tests';

test.describe(apps.ntfy.title, () => {
    for (const instance of apps.ntfy.instances) {
        test.describe(instance.title, () => {
            // TODO: Add test for HTTP->HTTPS redirects after real Let's Encrypt certificates
            createProxyStatusTests(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

            test('UI: Open', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('text="All notifications"').first()).toBeVisible({ timeout: 5000 });
            });

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });
        });
    }
});
