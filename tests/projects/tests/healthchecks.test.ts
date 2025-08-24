import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { axios, getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';

// type Healthcheck = {
//     badge_url: string,
//     desc: string,
//     failure_kw: string,
//     filter_body: boolean,
//     filter_subject: boolean,
//     grace: number,
//     last_ping: null | string,
//     manual_resume: boolean,
//     methods: string,
//     n_pings: number,
//     name: string,
//     next_ping: null | string,
//     schedule: string,
//     slug: string,
//     start_kw: string,
//     started: boolean,
//     status: string,
//     subject_fail: string,
//     subject: string,
//     success_kw: string,
//     tags: string,
//     tz: string,
//     unique_key: string,
//     uuid: string,
// };

test.describe(apps.healthchecks.title, () => {
    for (const instance of apps.healthchecks.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'bearer', path: `/projects/${getEnv(instance.url, 'PROMETHEUS_PROJECT')}/metrics`, token: getEnv(instance.url, 'API_KEY_READONLY') });
            createPrometheusTests(instance.url, { auth: 'none', path: `/projects/${getEnv(instance.url, 'PROMETHEUS_PROJECT')}/metrics/${getEnv(instance.url, 'API_KEY_READONLY')}` });

            test('API: Status endpoint', async () => {
                const response = await axios.get(`${instance.url}/api/v3/status`);
                expect(response.status, 'Response Status').toStrictEqual(200);
                expect(response.data, 'Response body').toStrictEqual('OK');
            });

            const apiKeys = [
                {
                    title: 'full API key',
                    key: getEnv(instance.url, 'API_KEY_READWRITE'),
                    status: 200,
                },
                {
                    title: 'readonly API key',
                    key: getEnv(instance.url, 'API_KEY_READONLY'),
                    status: 200,
                },
                {
                    title: 'wrong API key',
                    key: faker.string.alpha(10),
                    status: 401,
                },
                {
                    title: 'missing API key',
                    key: undefined,
                    status: 401,
                }
            ];
            for (const variant of apiKeys) {
                test(`API: List checks (${variant.title})`, async () => {
                    const headers: Record<string, string> = {};
                    if (!!variant.key) {
                        headers['X-Api-Key'] = variant.key;
                    }
                    const response = await axios.get(`${instance.url}/api/v3/checks`, { headers: headers });
                    expect(response.status, 'Response Status').toStrictEqual(variant.status);
                });

                test(`API: List badges (${variant.title})`, async () => {
                    const headers: Record<string, string> = {};
                    if (!!variant.key) {
                        headers['X-Api-Key'] = variant.key;
                    }
                    const response = await axios.get(`${instance.url}/api/v3/badges`, { headers: headers });
                    expect(response.status, 'Response Status').toStrictEqual(variant.status);
                });

                test(`API: List channels (${variant.title})`, async () => {
                    test.skip(variant.title.toLowerCase().includes('readonly')); // TODO: Find the reason this fails
                    const headers: Record<string, string> = {};
                    if (!!variant.key) {
                        headers['X-Api-Key'] = variant.key;
                    }
                    const response = await axios.get(`${instance.url}/api/v3/channels`, { headers: headers });
                    expect(response.status, 'Response Status').toStrictEqual(variant.status);
                });
            }

            test(`UI: Successful login - User test`, async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(/\/accounts\/login\/?$/);
                await page.locator('input[name="email"]').fill('test@matejhome.com');
                await page.locator('input[name="password"]').fill(getEnv(instance.url, 'TEST_PASSWORD'));
                await page.locator('button[type="submit"]:has-text("Log In")').click({ timeout: 10_000 });
                await page.waitForURL(/\/projects\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/checks\/?$/);
                await expect(page.locator('table#checks-table .checks-row').first()).toBeVisible();
            });

            test('UI: Unsuccessful login - Random user', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(/\/accounts\/login\/?$/);
                const originalUrl = page.url();
                await page.locator('input[name="email"]').fill(`${faker.string.alpha(8)}@healthchecks.matejhome.com`);
                await page.locator('input[name="password"]').fill(faker.string.alpha(10));
                await page.locator('button[type="submit"]:has-text("Log In")').click({ timeout: 10_000 });
                await page.waitForURL(/\/accounts\/login\/?$/);
                await expect(page.locator('.text-danger:has-text("Incorrect email or password.")')).toBeVisible();
                await expect(page, 'URL should not change').toHaveURL(originalUrl);
            });
        });
    }
});
