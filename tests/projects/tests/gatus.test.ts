import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { axios, getEnv } from '../../utils/utils';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps.gatus.title, () => {
    for (const instance of apps.gatus.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'basic' });
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            test('API: Prometheus metrics - User matej', async () => {
                const response = await axios.get(`${instance.url}/metrics`, {
                    auth: {
                        username: 'matej',
                        password: getEnv(instance.url, 'MATEJ_PASSWORD'),
                    },
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Prometheus metrics content', async () => {
                const response = await axios.get(`${instance.url}/metrics`, {
                    auth: {
                        username: 'prometheus',
                        password: getEnv(instance.url, 'PROMETHEUS_PASSWORD'),
                    },
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
                const content = response.data as string;
                await test.info().attach('prometheus.txt', { contentType: 'text/plain', body: content });
                const lines = content.split('\n');
                const metrics = [
                    'gatus_results_certificate_expiration_seconds',
                    'gatus_results_code_total',
                    'gatus_results_connected_total',
                    'gatus_results_duration_seconds',
                    'gatus_results_endpoint_success',
                    'gatus_results_total',
                    'promhttp_metric_handler_requests_in_flight',
                    'promhttp_metric_handler_requests_total',
                ];
                for (const metric of metrics) {
                    expect(lines.find((el) => el.startsWith(metric)), `Metric ${metric}`).toBeDefined();
                }
            });

            const validUsers = [
                {
                    username: 'matej',
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful open - User ${user.username}`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${user.username}:${getEnv(instance.url, 'ADMIN_PASSWORD')}`).toString('base64')}` });
                    await page.goto(instance.url);
                    await expect(page.locator('.animate-spin')).toBeVisible();
                    await expect(page.locator('.animate-spin')).not.toBeVisible({ timeout: 20_000 });
                    await expect(page.locator('#app .endpoint-group').first()).toBeVisible();
                });
            }

            const invalidUsers = [
                {
                    username: 'matej',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful open - ${user.random ? 'Random user' : `User ${user.username}`}`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${user.username}:${faker.string.alphanumeric(10)}`).toString('base64')}` });
                    await page.goto(instance.url);
                    await expect(page.locator('#app .endpoint-group').first()).not.toBeVisible();
                });
            }

            test('UI: Unsuccessful open - No user', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('#app .endpoint-group').first()).not.toBeVisible();
            });
        });
    }
});
