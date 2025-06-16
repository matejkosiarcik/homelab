import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { axios, getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps.jellyfin.title, () => {
    for (const instance of apps.jellyfin.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createHttpToHttpsRedirectTests(`${instance.url.replace('https://', 'http://')}:8096`);
            createPrometheusTests(instance.url, { auth: 'basic' });
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443, 8096]);
            createFaviconTests(instance.url);

            test('API: Health endpoint', async () => {
                const response = await axios.get(`${instance.url}/health`);
                expect(response.status, 'Response Status').toStrictEqual(200);
                expect(response.data, 'Response body').toStrictEqual('Healthy');
            });

            const users = [
                {
                    username: 'admin',
                },
                {
                    username: 'monika',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                }
            ];
            for (const variant of users) {
                if (!variant.random) {
                    test(`UI: Successful login - User ${variant.username}`, async ({ page }) => {
                        await page.goto(instance.url);
                        await page.waitForURL(/\/login\.html(?:\?.*)?$/);
                        await page.locator('input#txtManualName').waitFor({ timeout: 8000 });
                        await page.locator('input#txtManualName').fill(variant.username);
                        await page.locator('input#txtManualPassword').fill(getEnv(instance.url, `${variant.username}_PASSWORD`));
                        await page.locator('button[type="submit"]').click();
                        await page.waitForURL(`${instance.url}/web/#/home.html`);
                        await expect(page.locator('#indexPage.homePage')).toBeVisible();
                        await expect(page.locator('a[aria-label="Live TV"]')).toBeVisible();
                    });
                }

                test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(/\/login\.html(?:\?.*)?$/);
                    const originalUrl = page.url();
                    await page.locator('input#txtManualName').waitFor({ timeout: 8000 });
                    await page.locator('input#txtManualName').fill(variant.username);
                    await page.locator('input#txtManualPassword').fill(faker.string.alpha(10));
                    await page.locator('button[type="submit"]').click();
                    await expect(page.locator('.toast:has-text("Invalid username or password.")')).toBeVisible();
                    await expect(page, 'URL should not change').toHaveURL(originalUrl);
                });
            }
        });
    }
});
