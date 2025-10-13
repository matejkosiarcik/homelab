import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { axios, getEnv } from '../../utils/utils';
import { faker } from '@faker-js/faker';

test.describe(apps['docker-stats'].title, () => {
    for (const instance of apps['docker-stats'].instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'basic', path: '/metrics' });
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            const prometheusValidUsers = [
                {
                    username: 'matej',
                },
                {
                    username: 'homelab-viewer',
                },
                {
                    username: 'homelab-test',
                },
                {
                    username: 'prometheus',
                },
            ];
            for (const user of prometheusValidUsers) {
                test(`API: Get prometheus metrics - User ${user.username}`, async () => {
                    const response = await axios.get(`${instance.url}/metrics`, {
                        auth: {
                            username: user.username,
                            password: getEnv(instance.url, `${user.username}_PASSWORD`),
                        },
                    });
                    expect(response.status, 'Response Status').toStrictEqual(200);
                });
            }

            const prometheusInvalidUsers = [
                {
                    username: 'matej',
                },
                {
                    username: 'homelab-viewer',
                },
                {
                    username: 'homelab-test',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                },
            ];
            for (const user of prometheusInvalidUsers) {
                test(`API: Unsuccessful get prometheus metrics with bad password - ${user.random ? 'Random user' : `User ${user.username}`}`, async () => {
                    const response = await axios.get(`${instance.url}/metrics`, {
                        auth: {
                            username: user.username,
                            password: faker.string.alpha(10),
                        },
                    });
                    expect(response.status, 'Response Status').toStrictEqual(401);
                });

                test(`API: Unsuccessful get prometheus metrics without password - ${user.random ? 'Random user' : `User ${user.username}`}`, async () => {
                    const response = await axios.get(`${instance.url}/metrics`, {
                        auth: {
                            username: user.username,
                            password: '',
                        },
                    });
                    expect(response.status, 'Response Status').toStrictEqual(401);
                });
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
