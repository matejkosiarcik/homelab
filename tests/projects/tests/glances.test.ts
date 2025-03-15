import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { axios, getEnv } from '../../utils/utils';

test.describe(apps.glances.title, () => {
    for (const instance of apps.glances.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'basic' });
            createApiRootTest(instance.url, { status: 401 });
            createTcpTests(instance.url, [80, 443]);

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
                    test(`API: Successful get root - User ${variant.username}`, async () => {
                        const response = await axios.get(instance.url, {
                            auth: {
                                username: variant.username,
                                password: getEnv(instance.url, 'PASSWORD'),
                            },
                            timeout: 10_000,
                        });
                        expect(response.status, 'Response Status').toStrictEqual(200);
                    });

                    test(`UI: Successful open - User ${variant.username}`, async ({ page }) => {
                        await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${variant.username}:${getEnv(instance.url, 'PASSWORD')}`).toString('base64')}` });
                        await page.goto(instance.url);
                        await expect(page.locator('#app #cpu.plugin')).toBeVisible({ timeout: 10_000 });
                    });
                }

                test(`API: Unsuccessful get root with bad password - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async () => {
                    const response = await axios.get(instance.url, {
                        auth: {
                            username: variant.username,
                            password: faker.string.alphanumeric(10),
                        },
                        timeout: 10_000,
                    });
                    expect(response.status, 'Response Status').toStrictEqual(401);
                });

                test(`API: Unsuccessful get root without password - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async () => {
                    const response = await axios.get(instance.url, {
                        auth: {
                            username: variant.username,
                            password: '',
                        },
                        timeout: 10_000,
                    });
                    expect(response.status, 'Response Status').toStrictEqual(401);
                });

                test(`UI: Unsuccessful open with bad password - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${variant.username}:${faker.string.alphanumeric(10)}`).toString('base64')}` });
                    await page.goto(instance.url);
                    await expect(page.locator('#app #cpu.plugin')).not.toBeVisible();
                });

                test(`UI: Unsuccessful open without password - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${variant.username}:`).toString('base64')}` });
                    await page.goto(instance.url);
                    await expect(page.locator('#app #cpu.plugin')).not.toBeVisible();
                });
            }

            test('API: Unsuccessful get root - No user', async () => {
                const response = await axios.get(instance.url, { timeout: 10_000 });
                expect(response.status, 'Response Status').toStrictEqual(401);
            });

            test('UI: Unsuccessful open - No user', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('#app #cpu.plugin')).not.toBeVisible();
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
                    'glances_cloud_history_size',
                    'glances_connections_established',
                    'glances_connections_history_size',
                    'glances_connections_initiated',
                    'glances_connections_listen',
                    'glances_connections_nf_conntrack_count',
                    'glances_connections_nf_conntrack_max',
                    'glances_connections_nf_conntrack_percent',
                    'glances_connections_syn_recv',
                    'glances_connections_syn_sent',
                    'glances_connections_terminated',
                    'glances_core_history_size',
                    'glances_core_log',
                    'glances_core_phys',
                    'glances_cpu_cpucore',
                    'glances_cpu_ctx_switches',
                    'glances_cpu_ctx_switches_gauge',
                    'glances_cpu_ctx_switches_rate_per_sec',
                    'glances_cpu_guest',
                    'glances_cpu_history_size',
                    'glances_cpu_idle',
                    'glances_cpu_interrupts',
                    'glances_cpu_interrupts_gauge',
                    'glances_cpu_interrupts_rate_per_sec',
                    'glances_cpu_iowait',
                    'glances_cpu_irq',
                    'glances_cpu_nice',
                    'glances_cpu_soft_interrupts',
                    'glances_cpu_soft_interrupts_gauge',
                    'glances_cpu_soft_interrupts_rate_per_sec',
                    'glances_cpu_steal',
                    'glances_cpu_syscalls',
                    'glances_cpu_syscalls_gauge',
                    'glances_cpu_system',
                    'glances_cpu_time_since_update',
                    'glances_cpu_total',
                    'glances_cpu_user',
                    'glances_ip_history_size',
                    'glances_ip_mask_cidr',
                    'glances_load_cpucore',
                    'glances_load_history_size',
                    'glances_load_load_careful',
                    'glances_load_load_critical',
                    'glances_load_load_warning',
                    'glances_load_min1',
                    'glances_load_min15',
                    'glances_load_min5',
                    'glances_mem_active',
                    'glances_mem_available',
                    'glances_mem_buffers',
                    'glances_mem_cached',
                    'glances_mem_free',
                    'glances_mem_history_size',
                    'glances_mem_inactive',
                    'glances_mem_mem_careful',
                    'glances_mem_mem_critical',
                    'glances_mem_mem_warning',
                    'glances_mem_percent',
                    'glances_mem_shared',
                    'glances_mem_total',
                    'glances_mem_used',
                    'glances_memswap_free',
                    'glances_memswap_history_size',
                    'glances_memswap_memswap_careful',
                    'glances_memswap_memswap_critical',
                    'glances_memswap_memswap_warning',
                    'glances_memswap_percent',
                    'glances_memswap_sin',
                    'glances_memswap_sout',
                    'glances_memswap_time_since_update',
                    'glances_memswap_total',
                    'glances_memswap_used',
                    'glances_network_lo_bytes_all',
                    'glances_network_lo_bytes_all_gauge',
                    'glances_network_lo_bytes_all_rate_per_sec',
                    'glances_network_lo_bytes_recv',
                    'glances_network_lo_bytes_recv_gauge',
                    'glances_network_lo_bytes_recv_rate_per_sec',
                    'glances_network_lo_bytes_sent',
                    'glances_network_lo_bytes_sent_gauge',
                    'glances_network_lo_bytes_sent_rate_per_sec',
                    'glances_network_lo_history_size',
                    'glances_network_lo_network_rx_careful',
                    'glances_network_lo_network_rx_critical',
                    'glances_network_lo_network_rx_warning',
                    'glances_network_lo_network_tx_careful',
                    'glances_network_lo_network_tx_critical',
                    'glances_network_lo_network_tx_warning',
                    'glances_network_lo_speed',
                    'glances_network_lo_time_since_update',
                    'glances_percpu_0_cpu_number',
                    'glances_percpu_0_guest',
                    'glances_percpu_0_guest_nice',
                    'glances_percpu_0_history_size',
                    'glances_percpu_0_idle',
                    'glances_percpu_0_iowait',
                    'glances_percpu_0_irq',
                    'glances_percpu_0_nice',
                    'glances_percpu_0_percpu_system_careful',
                    'glances_percpu_0_percpu_system_critical',
                    'glances_percpu_0_percpu_system_warning',
                    'glances_percpu_0_percpu_user_careful',
                    'glances_percpu_0_percpu_user_critical',
                    'glances_percpu_0_percpu_user_warning',
                    'glances_percpu_0_softirq',
                    'glances_percpu_0_steal',
                    'glances_percpu_0_system',
                    'glances_percpu_0_total',
                    'glances_percpu_0_user',
                    'glances_processcount_history_size',
                    'glances_processcount_pid_max',
                    'glances_processcount_running',
                    'glances_processcount_sleeping',
                    'glances_processcount_thread',
                    'glances_processcount_total',
                    'glances_raid_history_size',
                    'glances_system_history_size',
                    'glances_system_system_refresh',
                    'glances_uptime_history_size',
                    'glances_uptime_seconds',
                ];
                for (const metric of metrics) {
                    expect(lines.find((el) => el.startsWith(metric)), `Metric ${metric}`).toBeDefined();
                }
            });
        });
    }
});
