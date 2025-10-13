import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { axios, getEnv } from '../../utils/utils';
import { faker } from '@faker-js/faker';

test.describe(apps.nodeexporter.title, () => {
    for (const instance of apps.nodeexporter.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'basic' });
            createApiRootTest(instance.url, { title: 'Unauthenticated', status: 401 });
            createApiRootTest(instance.url, {
                title: 'Authenticated (admin)',
                headers: {
                    Authorization: `Basic ${Buffer.from(`admin:${getEnv(instance.url, 'ADMIN_PASSWORD')}`).toString('base64')}`
                },
            });
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            const validUsers = [
                {
                    username: 'matej',
                },
                {
                    username: 'homelab-viewer',
                },
                {
                    username: 'homelab-test',
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful open - User ${user.username}`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`admin:${getEnv(instance.url, `${user.username}_PASSWORD`)}`).toString('base64')}` });
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/`);
                    await expect(page.locator('h1:has-text("Node Exporter")')).toBeVisible();
                    await expect(page.locator('h2:has-text("Prometheus Node Exporter")')).toBeVisible();
                });

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

            const invalidUsers = [
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
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful open with bad password - ${user.random ? 'Random user' : `User ${user.username}`}`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${user.username}:${faker.string.alphanumeric(10)}`).toString('base64')}` });
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/`);
                    await expect(page.locator('h1:has-text("Node Exporter")')).not.toBeVisible();
                    await expect(page.locator('h2:has-text("Prometheus Node Exporter")')).not.toBeVisible();
                });

                test(`UI: Unsuccessful open without password - ${user.random ? 'Random user' : `User ${user.username}`}`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${user.username}:`).toString('base64')}` });
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/`);
                    await expect(page.locator('h1:has-text("Node Exporter")')).not.toBeVisible();
                    await expect(page.locator('h2:has-text("Prometheus Node Exporter")')).not.toBeVisible();
                });
            }

            test('UI: Unsuccessful open - No user', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('h1:has-text("Node Exporter")')).not.toBeVisible();
                await expect(page.locator('h2:has-text("Prometheus Node Exporter")')).not.toBeVisible();
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
                    'node_boot_time_seconds',
                    'node_context_switches_total',
                    'node_cpu_frequency_max_hertz',
                    'node_cpu_frequency_min_hertz',
                    'node_cpu_guest_seconds_total',
                    'node_cpu_scaling_frequency_hertz',
                    'node_cpu_scaling_frequency_max_hertz',
                    'node_cpu_scaling_frequency_min_hertz',
                    'node_cpu_scaling_governor',
                    'node_cpu_seconds_total',
                    'node_disk_discard_time_seconds_total',
                    'node_disk_discarded_sectors_total',
                    'node_disk_discards_completed_total',
                    'node_disk_discards_merged_total',
                    'node_disk_flush_requests_time_seconds_total',
                    'node_disk_flush_requests_total',
                    'node_disk_info',
                    'node_disk_io_now',
                    'node_disk_io_time_seconds_total',
                    'node_disk_io_time_weighted_seconds_total',
                    'node_disk_read_bytes_total',
                    'node_disk_read_time_seconds_total',
                    'node_disk_reads_completed_total',
                    'node_disk_reads_merged_total',
                    'node_disk_write_time_seconds_total',
                    'node_disk_writes_completed_total',
                    'node_disk_writes_merged_total',
                    'node_disk_written_bytes_total',
                    'node_entropy_available_bits',
                    'node_entropy_pool_size_bits',
                    'node_exporter_build_info',
                    'node_filefd_allocated',
                    'node_filefd_maximum',
                    'node_filesystem_avail_bytes',
                    'node_filesystem_device_error',
                    'node_filesystem_files',
                    'node_filesystem_files_free',
                    'node_filesystem_free_bytes',
                    'node_filesystem_mount_info',
                    'node_filesystem_purgeable_bytes',
                    'node_filesystem_readonly',
                    'node_filesystem_size_bytes',
                    'node_forks_total',
                    'node_intr_total',
                    'node_load1',
                    'node_load15',
                    'node_load5',
                    'node_memory_Active_bytes',
                    'node_network_up',
                    'node_os_info',
                    'node_os_version',
                    'node_time_seconds',
                    'node_time_zone_offset_seconds',
                ];
                for (const metric of metrics) {
                    expect(lines.find((el) => el.startsWith(metric)), `Metric ${metric}`).toBeDefined();
                }
            });
        });
    }
});
