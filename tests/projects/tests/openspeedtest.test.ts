import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createFaviconTests, createHttpsToHttpRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import axios from 'axios';

test.describe(apps.openspeedtest.title, () => {
    for (const instance of apps.openspeedtest.instances) {
        test.describe(instance.title, () => {
            createHttpsToHttpRedirectTests(instance.url);
            createProxyTests(instance.url, { redirect: false });
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            test('API: Get root - HTTP', async () => {
                const response = await axios.get(instance.url.replace('https://', 'http://'), { maxRedirects: 0 });
                expect(response.status, 'Response Status').toStrictEqual(200);
                expect(response.config.url, 'Response URL').toStrictEqual(instance.url.replace('https://', 'http://'));
            });

            test('API: Get root - HTTPS', async () => {
                const response = await axios.get(instance.url.replace('http://', 'https://'), { maxRedirects: 0, validateStatus: () => true });
                expect(response.status, 'Response Status').toStrictEqual(302);
                expect(response.headers['location'], 'Response header location').toStrictEqual(instance.url.replace('https://', 'http://'));
            });

            test('UI: Open', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('#OpenSpeedtest')).toBeVisible({ timeout: 5000 });
            });
        });
    }
});
