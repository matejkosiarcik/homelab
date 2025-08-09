import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { axios, getEnv } from '../../utils/utils';

test.describe(apps['docker-stats'].title, () => {
    for (const instance of apps['docker-stats'].instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'basic', path: '/' });
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            test('API: Prometheus metrics content', async () => {
                const response = await axios.get(`${instance.url}`, {
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
                    'dockerstats_blockio_read_bytes',
                    'dockerstats_blockio_written_bytes',
                    'dockerstats_cpu_usage_ratio',
                    'dockerstats_memory_limit_bytes',
                    'dockerstats_memory_usage_bytes',
                    'dockerstats_memory_usage_ratio',
                    'dockerstats_memory_usage_rss_bytes',
                    'dockerstats_network_received_bytes',
                    'dockerstats_network_transmitted_bytes',
                ];
                for (const metric of metrics) {
                    expect(lines.find((el) => el.startsWith(metric)), `Metric ${metric}`).toBeDefined();
                }
            });
        });
    }
});
