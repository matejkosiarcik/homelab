import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { axios, getEnv } from '../../utils/utils';
import { createApiRootTest, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTest } from '../../utils/tests';

test.describe(apps.gatus.title, () => {
    for (const instance of apps.gatus.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'basic' });
            createApiRootTest(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

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

            const users = [
                {
                    username: 'admin',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                }
            ];
            for (const variant of users) {
                if (!variant.random) {
                    test(`UI: Successful open - User ${variant.username}`, async ({ page }) => {
                        await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${variant.username}:${getEnv(instance.url, 'ADMIN_PASSWORD')}`).toString('base64')}` });
                        await page.goto(instance.url);
                        await expect(page.locator('.animate-spin')).toBeVisible();
                        await expect(page.locator('.animate-spin')).not.toBeVisible({ timeout: 20_000 });
                        await expect(page.locator('#results .endpoint-group').first()).toBeVisible();
                    });
                }

                test(`UI: Unsuccessful open - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${variant.username}:${faker.string.alphanumeric(10)}`).toString('base64')}` });
                    await page.goto(instance.url);
                    await expect(page.locator('#results .endpoint-group').first()).not.toBeVisible();
                });
            }

            test('UI: Unsuccessful open - No user', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('#results .endpoint-group').first()).not.toBeVisible();
            });
        });
    }
});
