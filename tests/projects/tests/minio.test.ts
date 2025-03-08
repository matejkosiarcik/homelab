import https from 'node:https';
import axios from 'axios';
import UserAgent from 'user-agents';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTest } from '../../utils/tests';

test.describe(apps.minio.title, () => {
    for (const instance of apps.minio.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'token', path: '/minio/v2/metrics/cluster' });

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
                createTcpTest(instance.consoleUrl, port, 'console');
            }

            test('API: Root', async () => {
                const userAgent = new UserAgent([/Chrome/, { platform: 'Win32', vendor: 'Google Inc.' }]).toString();
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999, headers: { 'User-Agent': userAgent }, validateStatus: () => true});
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Redirect to console', async () => {
                const userAgent = new UserAgent([/Chrome/, { platform: 'Win32', vendor: 'Google Inc.' }]).toString();
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, headers: { 'User-Agent': userAgent }, validateStatus: () => true });
                expect(response.status, 'Response Status').toStrictEqual(307);
                expect(response.headers['location'], 'Response header location').toStrictEqual(instance.consoleUrl);
            });

            test('API: Console root', async () => {
                const response = await axios.get(instance.consoleUrl, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Health endpoint (live)', async () => {
                const response = await axios.get(`${instance.url}/minio/health/live`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Health endpoint (cluster)', async () => {
                const response = await axios.get(`${instance.url}/minio/health/cluster`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Health endpoint (cluster-read)', async () => {
                const response = await axios.get(`${instance.url}/minio/health/cluster/read`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Prometheus metrics content', async () => {
                const response = await axios.get(`${instance.url}/minio/v2/metrics/cluster`, {
                    headers: { Authorization: `Bearer ${getEnv(instance.url, 'PROMETHEUS_BEARER_TOKEN')}` },
                    maxRedirects: 999,
                    validateStatus: () => true,
                    httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
                const content = response.data as string;
                await test.info().attach('prometheus.txt', { contentType: 'text/plain', body: content });
                const lines = content.split('\n');
                const metrics = [
                    'minio_audit_failed_messages',
                    'minio_audit_target_queue_length',
                    'minio_audit_total_messages',
                    'minio_cluster_bucket_total',
                    'minio_cluster_capacity_raw_free_bytes',
                    'minio_cluster_capacity_raw_total_bytes',
                    'minio_cluster_capacity_usable_free_bytes',
                    'minio_cluster_capacity_usable_total_bytes',
                    'minio_cluster_drive_offline_total',
                    'minio_cluster_drive_online_total',
                    'minio_cluster_drive_total',
                    'minio_cluster_health_erasure_set_healing_drives',
                    'minio_cluster_health_erasure_set_online_drives',
                    'minio_cluster_health_erasure_set_read_quorum',
                    'minio_cluster_health_erasure_set_status',
                    'minio_cluster_health_erasure_set_write_quorum',
                    'minio_cluster_health_status',
                    'minio_cluster_nodes_offline_total',
                    'minio_cluster_nodes_online_total',
                    'minio_cluster_objects_size_distribution',
                    'minio_cluster_objects_version_distribution',
                    'minio_cluster_usage_deletemarker_total',
                    'minio_cluster_usage_object_total',
                    'minio_cluster_usage_total_bytes',
                    'minio_cluster_usage_version_total',
                    'minio_cluster_webhook_failed_messages',
                    'minio_cluster_webhook_online',
                    'minio_cluster_webhook_queue_length',
                    'minio_cluster_webhook_total_messages',
                    'minio_cluster_write_quorum',
                    'minio_node_file_descriptor_limit_total',
                    'minio_node_file_descriptor_open_total',
                    'minio_node_go_routine_total',
                    'minio_node_ilm_expiry_missed_freeversions',
                    'minio_node_ilm_expiry_missed_tasks',
                    'minio_node_ilm_expiry_missed_tierjournal_tasks',
                    'minio_node_ilm_expiry_num_workers',
                    'minio_node_ilm_expiry_pending_tasks',
                    'minio_node_ilm_transition_active_tasks',
                    'minio_node_ilm_transition_missed_immediate_tasks',
                    'minio_node_ilm_transition_pending_tasks',
                    'minio_node_ilm_versions_scanned',
                    'minio_node_io_rchar_bytes',
                    'minio_node_io_read_bytes',
                    'minio_node_io_wchar_bytes',
                    'minio_node_io_write_bytes',
                    'minio_node_process_cpu_total_seconds',
                    'minio_node_process_resident_memory_bytes',
                    'minio_node_process_starttime_seconds',
                    'minio_node_process_uptime_seconds',
                    'minio_node_scanner_bucket_scans_finished',
                    'minio_node_scanner_bucket_scans_started',
                    'minio_node_scanner_directories_scanned',
                    'minio_node_scanner_objects_scanned',
                    'minio_node_scanner_versions_scanned',
                    'minio_node_syscall_read_total',
                    'minio_node_syscall_write_total',
                    'minio_notify_events_errors_total',
                    'minio_notify_events_sent_total',
                    'minio_notify_events_skipped_total',
                    'minio_s3_requests_4xx_errors_total',
                    'minio_s3_requests_errors_total',
                    'minio_s3_requests_incoming_total',
                    'minio_s3_requests_inflight_total',
                    'minio_s3_requests_rejected_auth_total',
                    'minio_s3_requests_rejected_header_total',
                    'minio_s3_requests_rejected_invalid_total',
                    'minio_s3_requests_rejected_timestamp_total',
                    'minio_s3_requests_total',
                    'minio_s3_requests_ttfb_seconds_distribution',
                    'minio_s3_requests_waiting_total',
                    'minio_s3_traffic_received_bytes',
                    'minio_s3_traffic_sent_bytes',
                    'minio_software_commit_info',
                    'minio_software_version_info',
                    'minio_usage_last_activity_nano_seconds',
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
                    username: 'user',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                }
            ];
            for (const variant of users) {
                if (!variant.random) {
                    test(`UI: Successful login - User ${variant.username}`, async ({ page }) => {
                        await page.goto(instance.consoleUrl);
                        await page.waitForURL(`${instance.consoleUrl}/login`);
                        await page.locator('input#accessKey').fill(variant.username);
                        await page.locator('input#secretKey').fill(getEnv(instance.url, `${variant.username}_PASSWORD`));
                        await page.locator('button#do-login[type="submit"]').click();
                        await page.waitForURL(`${instance.consoleUrl}/browser`);
                        await expect(page.locator('#root .menuItems')).toBeVisible();
                        await expect(page.locator('main.mainPage .page-header:has-text("Object Browser")')).toBeVisible();
                    });
                }

                test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.goto(instance.consoleUrl);
                    await page.waitForURL(`${instance.consoleUrl}/login`);
                    const originalUrl = page.url();
                    await page.locator('input#accessKey').fill(variant.username);
                    await page.locator('input#secretKey').fill(faker.string.alpha(10));
                    await page.locator('button#do-login[type="submit"]').click();
                    await expect(page.locator('.messageTruncation:has-text("invalid Login.")')).toBeVisible();
                    expect(page.url(), 'URL should not change').toStrictEqual(originalUrl);
                });
            }
        });
    }
});
