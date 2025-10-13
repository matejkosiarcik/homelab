import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { axios, getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';

type SpeedtestTrackerHealthcheckResponse = {
    message: string,
};

test.describe(apps.speedtesttracker.title, () => {
    for (const instance of apps.speedtesttracker.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            test('API: Healthcheck', async () => {
                const response = await axios.get(`${instance.url}/api/healthcheck`);
                expect(response.status, 'Response Status').toStrictEqual(200);
                const body = response.data as SpeedtestTrackerHealthcheckResponse;
                expect(body.message, 'Response Message').toMatch(/.+/);
            });

            const validUsers = [
                {
                    email: 'matej@matejhome.com'
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful login - User ${user.email.split('@')[0]}`, async ({ page }) => {
                    await page.goto(`${instance.url}/admin/login`);
                    await page.locator('form input[id="data.email"][type="email"]').waitFor({ state: 'visible', timeout: 6000 });
                    await page.locator('form input[id="data.email"][type="email"]').fill(user.email);
                    await page.locator('form input[id="data.password"][type="password"]').fill(getEnv(instance.url, `${user.email.split('@')[0]}_PASSWORD`));
                    await page.locator('form button:has-text("Sign in")').click();
                    await page.waitForURL(`${instance.url}/admin`);
                    await expect(page.locator('header h1:has-text("Dashboard")')).toBeVisible();
                    await expect(page.locator('main .fi-wi-stats-overview-stat').first()).toBeVisible();
                });
            }

            const invalidUsers = [
                {
                    email: 'matej@matejhome.com',
                },
                {
                    email: `${faker.string.alpha(10)}@homelab.matejhome.com`,
                    random: true,
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful login - ${user.random ? 'Random user' : `User ${user.email.split('@')[0]}`}`, async ({ page }) => {
                    await page.goto(`${instance.url}/admin/login`);
                    await page.locator('form input[id="data.email"][type="email"]').waitFor({ state: 'visible', timeout: 6000 });
                    const originalUrl = page.url();
                    await page.locator('form input[id="data.email"][type="email"]').fill(user.email);
                    await page.locator('form input[id="data.password"][type="password"]').fill(faker.string.alpha(10));
                    await page.locator('form button:has-text("Sign in")').click();
                    await expect(page.locator('.fi-fo-field-wrp-error-message:has-text("These credentials do not match our records.")')).toBeVisible();
                    await expect(page, 'URL should not change').toHaveURL(originalUrl);
                });
            }

            test('UI: Open', async ({ page }) => {
                await page.goto(instance.url);
                // await expect(page.locator('.fi-wi-stats-overview-stat').first()).toBeVisible({ timeout: 5000 }); // NOTE: Unauthenticate dashboard is disabled
                await page.waitForURL(`${instance.url}/admin/login`);
            });
        });
    }
});
