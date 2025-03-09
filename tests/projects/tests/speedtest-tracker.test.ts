import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createApiRootTest, createHttpToHttpsRedirectTests, createProxyTests, createTcpTest } from '../../utils/tests';

type SpeedtestTrackerHealthcheckResponse = {
    message: string,
};

test.describe(apps['speedtest-tracker'].title, () => {
    for (const instance of apps['speedtest-tracker'].instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

            test('API: Healthcheck', async () => {
                const response = await axios.get(`${instance.url}/api/healthcheck`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
                const body = response.data as SpeedtestTrackerHealthcheckResponse;
                expect(body.message, 'Response Message').toMatch(/.+/);
            });

            const users = [
                {
                    username: 'admin',
                    email: 'admin@speedtest-tracker.home',
                },
                {
                    username: faker.string.alpha(10),
                    email: `${faker.string.alpha(10)}@speedtest-tracker.home`,
                    random: true,
                }
            ];
            for (const variant of users) {
                if (!variant.random) {
                    test(`UI: Successful login - User ${variant.username}`, async ({ page }) => {
                        await page.goto(`${instance.url}/admin/login`);
                        await page.locator('form input[id="data.email"][type="email"]').waitFor({ state: 'visible', timeout: 6000 });
                        await page.locator('form input[id="data.email"][type="email"]').fill(variant.email);
                        await page.locator('form input[id="data.password"][type="password"]').fill(getEnv(instance.url, `${variant.username}_PASSWORD`));
                        await page.locator('form button:has-text("Sign in")').click();
                        await page.waitForURL(`${instance.url}/admin`);
                        await expect(page.locator('header h1:has-text("Dashboard")')).toBeVisible();
                        await expect(page.locator('main .fi-wi-stats-overview-stat').first()).toBeVisible();
                    });
                }

                test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.goto(`${instance.url}/admin/login`);
                    await page.locator('form input[id="data.email"][type="email"]').waitFor({ state: 'visible', timeout: 6000 });
                    const originalUrl = page.url();
                    await page.locator('form input[id="data.email"][type="email"]').fill(variant.email);
                    await page.locator('form input[id="data.password"][type="password"]').fill(faker.string.alpha(10));
                    await page.locator('form button:has-text("Sign in")').click();
                    await expect(page.locator('.fi-fo-field-wrp-error-message:has-text("These credentials do not match our records.")')).toBeVisible();
                    expect(page.url(), 'URL should not change').toStrictEqual(originalUrl);
                });
            }

            test('UI: Open', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('.fi-wi-stats-overview-stat').first()).toBeVisible({ timeout: 5000 });
            });
        });
    }
});
