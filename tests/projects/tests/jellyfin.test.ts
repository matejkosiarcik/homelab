import { faker } from '@faker-js/faker';
import { expect, test } from '#/playwright/test.ts';
import { axios, getEnv } from '#/utils/utils.ts';
import { apps } from '#/utils/apps.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '#/utils/tests.ts';

const app = apps.jellyfin;

test.describe(app.title, () => {
    for (const instance of app.instances) {
        if ('enabled' in instance && instance.enabled === false) {
            test.skip(`Instance ${app.title} ${instance.title} is disabled`, () => {});
            continue;
        }

        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createHttpToHttpsRedirectTests(`${instance.url.replace('https://', 'http://')}:8096`);
            createPrometheusTests(instance.url, { auth: 'basic' });
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443, 8096]);
            createFaviconTests(instance.url);

            test('API: Prometheus metrics content', async () => {
                const response = await test.step('Request server', async () => {
                    const response = await axios.get(`${instance.url}/metrics`, {
                        auth: {
                            username: 'prometheus',
                            password: getEnv(instance.url, 'PROMETHEUS_PASSWORD'),
                        },
                    });
                    expect(response.status, 'Response Status').toStrictEqual(200);
                    return response;
                });

                await test.step('Validate response', async () => {
                    const content = response.data as string;
                    await test.info().attach('prometheus.txt', { contentType: 'text/plain', body: content });
                    const lines = content.split('\n');
                    const metrics = [
                        'dotnet_build_info',
                        'dotnet_contention_total',
                        'microsoft_aspnetcore_hosting_current_requests',
                        'microsoft_aspnetcore_hosting_failed_requests',
                        'microsoft_aspnetcore_hosting_total_requests',
                        'process_cpu_count',
                        'process_cpu_seconds_total',
                        'process_num_threads',
                        'prometheus_net_metric_families',
                        'system_net_http_current_requests',
                        'system_net_http_requests_failed',
                        'system_net_http_requests_started',
                        'system_runtime_cpu_usage',
                    ];
                    for (const metric of metrics) {
                        expect(lines.find((el) => el.startsWith(metric)), `Metric ${metric}`).toBeDefined();
                    }
                });
            });

            test('API: Health endpoint', async () => {
                const response = await test.step('Request server', async () => {
                    const response = await axios.get(`${instance.url}/health`);
                    expect(response.status, 'Response Status').toStrictEqual(200);
                    return response;
                });

                await test.step('Validate response', async () => {
                    expect(response.data, 'Response body').toStrictEqual('Healthy');
                });
            });

            const validUsers = [
                {
                    username: 'matej',
                },
                {
                    username: 'monika',
                },
                {
                    username: 'homelab-admin',
                },
                {
                    username: 'homelab-test',
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful login - User ${user.username}`, async ({ page }) => {
                    await test.step('Open login', async () => {
                        await page.goto(instance.url);
                        await page.waitForURL(/\/web\/#\/login(?:\?.*)?/);
                        await page.locator('input#txtManualName').waitFor({ timeout: 8000 });
                    });

                    await test.step('Login', async () => {
                        await page.locator('input#txtManualName').fill(user.username);
                        await page.locator('input#txtManualPassword').fill(getEnv(instance.url, `${user.username}_PASSWORD`));
                        await page.locator('button[type="submit"]').click({ noWaitAfter: true });
                    });

                    await test.step('Validate successful login', async () => {
                        await page.waitForURL(`${instance.url}/web/#/home`);
                        await expect(page.locator('#indexPage.homePage')).toBeVisible();
                        await expect(page.locator('a[aria-label="Live TV"]')).toBeVisible();
                    });
                });
            }

            const invalidUsers = [
                {
                    username: 'homelab-test',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful login - ${user.random ? 'Random user' : `User ${user.username}`}`, async ({ page }) => {
                    const originalUrl = await test.step('Open login', async () => {
                        await page.goto(instance.url);
                        await page.waitForURL(/\/web\/#\/login(?:\?.*)?/);
                        const loginUrl = page.url();
                        await page.locator('input#txtManualName').waitFor({ timeout: 8000 });
                        return loginUrl;
                    });

                    await test.step('Attempt login', async () => {
                        await page.locator('input#txtManualName').fill(user.username);
                        await page.locator('input#txtManualPassword').fill(faker.string.alpha(10));
                        await page.locator('button[type="submit"]').click();
                    });

                    await test.step('Validate unsuccessful login', async () => {
                        await expect(page.locator('.toast:has-text("Invalid username or password.")')).toBeVisible();
                        await expect(page, 'URL should not change').toHaveURL(originalUrl);
                    });
                });
            }
        });
    }
});
