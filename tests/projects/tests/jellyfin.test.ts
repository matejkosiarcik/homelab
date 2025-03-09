import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createApiRootTest, createHttpToHttpsRedirectTests, createProxyTests, createTcpTest } from '../../utils/tests';

test.describe(apps.jellyfin.title, () => {
    for (const instance of apps.jellyfin.instances) {
        test.describe(instance.title, () => {
            const httpUrl8096 = `${instance.url.replace('https://', 'http://')}:8096`; // TODO: Remove after real Let's encrypt certificates

            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createApiRootTest(httpUrl8096, { title: ':8096' });

            for (const port of [80, 443, 8096]) {
                createTcpTest(instance.url, port);
            }

            test('API: Health endpoint', async () => {
                const response = await axios.get(`${instance.url}/health`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
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

                    test(`UI: Successful login on port 8096 - User ${variant.username}`, async ({ page }) => {
                        await page.goto(httpUrl8096);
                        await page.waitForURL(/\/login\.html(?:\?.*)?$/);
                        await page.locator('input#txtManualName').waitFor({ timeout: 8000 });
                        await page.locator('input#txtManualName').fill(variant.username);
                        await page.locator('input#txtManualPassword').fill(getEnv(instance.url, `${variant.username}_PASSWORD`));
                        await page.locator('button[type="submit"]').click();
                        await page.waitForURL(`${httpUrl8096}/web/#/home.html`);
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
                    expect(page.url(), 'URL should not change').toStrictEqual(originalUrl);
                });

                test(`UI: Unsuccessful login on port 8096 - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.goto(httpUrl8096);
                    await page.waitForURL(/\/login\.html(?:\?.*)?$/);
                    const originalUrl = page.url();
                    await page.locator('input#txtManualName').waitFor({ timeout: 8000 });
                    await page.locator('input#txtManualName').fill(variant.username);
                    await page.locator('input#txtManualPassword').fill(faker.string.alpha(10));
                    await page.locator('button[type="submit"]').click();
                    await expect(page.locator('.toast:has-text("Invalid username or password.")')).toBeVisible();
                    expect(page.url(), 'URL should not change').toStrictEqual(originalUrl);
                });
            }
        });
    }
});
