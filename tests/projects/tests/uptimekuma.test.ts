import { expect, test } from '@playwright/test';
import { apps } from '#/utils/apps.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '#/utils/tests.ts';
import { faker } from '@faker-js/faker';
import { axios, getEnv } from '#/utils/utils.ts';

const app = apps.uptimekuma;

test.describe(app.title, () => {
    for (const instance of app.instances) {
        if ('enabled' in instance && instance.enabled === false) {
            test.skip(`Instance ${app.title} ${instance.title} is disabled`, () => {});
            continue;
        }

        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);
            createPrometheusTests(instance.url, {
                auth: 'basic',
                username: 'prometheus',
                token: getEnv(instance.url, 'API_KEY'),
            });

            test('API: Prometheus metrics content', async () => {
                const response = await axios.get(`${instance.url}/metrics`, {
                    auth: {
                        username: 'prometheus',
                        password: getEnv(instance.url, 'API_KEY'),
                    },
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
                const content = response.data as string;
                await test.info().attach('prometheus.txt', { contentType: 'text/plain', body: content });
                const lines = content.split('\n');
                const metrics = [
                    'app_version',
                    'expressjs_number_of_open_connections',
                    'monitor_cert_days_remaining',
                    'monitor_cert_is_valid',
                    'monitor_response_time_seconds',
                    'monitor_response_time',
                    'monitor_status',
                    'monitor_uptime_ratio',
                ];
                for (const metric of metrics) {
                    expect(lines.find((el) => el.startsWith(metric)), `Metric ${metric}`).toBeDefined();
                }
            });

            const validUsers = [
                {
                    username: 'matej'
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful login - User ${user.username}`, async ({ page }) => {
                    // Load page
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/dashboard`);
                    await expect(page.locator('.form-container form')).toBeVisible();
                    // await expect(PageRevealEvent.getByRole('heading', { name: 'All Messages'})).not.toBeVisible();

                    // Fill in form
                    await page.locator('form input[autocomplete="username"]').fill(user.username);
                    await page.locator('form input[type="password"]').fill(getEnv(instance.url, `${user.username}_PASSWORD`));
                    await page.locator('form button[type="submit"]:has-text("Log In")').click();

                    // Verify login
                    await expect(page.locator('.form-container form')).not.toBeVisible();
                    await expect(page.getByRole('heading', { name: 'Quick Stats'})).toBeVisible();
                });
            }

            const invalidUsers = [
                {
                    username: faker.string.alpha(10),
                    random: true,
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful login - ${user.random ? 'Random user' : `User ${user.username}`}`, async ({ page }) => {
                    // Load page
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/dashboard`);
                    await expect(page.locator('.form-container form')).toBeVisible();
                    await expect(page.getByRole('alert', { name: 'Incorrect username or password.' })).not.toBeVisible();

                    // Fill in form
                    await page.locator('form input[autocomplete="username"]').fill(user.username);
                    await page.locator('form input[type="password"]').fill(faker.string.alpha(10));
                    await page.locator('form button[type="submit"]:has-text("Log In")').click();

                    // Verify fail
                    await expect(page.locator('[role="alert"]:has-text("Incorrect username or password.")')).toBeVisible();
                });
            }
        });
    }
});
