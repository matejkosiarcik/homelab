import { expect, test } from '#/playwright/test.ts';
import { apps } from '#/utils/apps.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '#/utils/tests.ts';
import { axios, getEnv } from '#/utils/utils.ts';

const app = apps.libretranslate;

test.describe(app.title, () => {
    for (const instance of app.instances) {
        if ('enabled' in instance && instance.enabled === false) {
            test.skip(`Instance ${app.title} ${instance.title} is disabled`, () => {});
            continue;
        }

        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url, { status: 401 });
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'basic' });

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
                        'libretranslate_http_request_duration_seconds_count',
                        'libretranslate_http_request_duration_seconds_sum',
                        'libretranslate_http_requests_in_flight',
                    ];
                    for (const metric of metrics) {
                        expect(lines.find((el) => el.startsWith(metric)), `Metric ${metric}`).toBeDefined();
                    }
                });
            });

            test.skip('PLACEHOLDER', () => {
                // TODO: Finish tests
            });
        });
    }
});
