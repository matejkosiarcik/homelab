import UserAgent from 'user-agents';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { axios, getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps.minio.title, () => {
    for (const instance of apps.minio.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createHttpToHttpsRedirectTests(instance.consoleUrl, { title: 'console' });
            createProxyTests(instance.url);
            createProxyTests(instance.consoleUrl, { title: 'console' });
            createPrometheusTests(instance.url, { auth: 'bearer', path: '/minio/v2/metrics/cluster' });
            createApiRootTest(instance.url, {
                headers: {
                    'User-Agent': new UserAgent([/Chrome/, { platform: 'Win32', vendor: 'Google Inc.' }]).toString()
                }
            });
            createTcpTests(instance.url, [80, 443]);
            createTcpTests(instance.consoleUrl, [80, 443], { title: 'console' });
            createFaviconTests(instance.url);
            createFaviconTests(instance.consoleUrl, { title: 'console' });

            test('API: Redirect to console', async () => {
                const userAgent = new UserAgent([/Chrome/, { platform: 'Win32', vendor: 'Google Inc.' }]).toString();
                const response = await axios.get(instance.url, {
                    headers: {
                        'User-Agent': userAgent,
                    },
                    maxRedirects: 0,
                });
                expect(response.status, 'Response Status').toStrictEqual(307);
                expect(response.headers['location'], 'Response header location').toStrictEqual(instance.consoleUrl);
            });

            test('API: Console root', async () => {
                const response = await axios.get(instance.consoleUrl);
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Health endpoint (live)', async () => {
                const response = await axios.get(`${instance.url}/minio/health/live`);
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Health endpoint (cluster)', async () => {
                const response = await axios.get(`${instance.url}/minio/health/cluster`);
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Health endpoint (cluster-read)', async () => {
                const response = await axios.get(`${instance.url}/minio/health/cluster/read`);
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Prometheus metrics content', async () => {
                const response = await axios.get(`${instance.url}/minio/v2/metrics/cluster`, {
                    headers: {
                        Authorization: `Bearer ${getEnv(instance.url, 'PROMETHEUS_BEARER_TOKEN')}`,
                    },
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
                    // 'minio_node_io_read_bytes',
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

            test('UI: Successful login - User test', async ({ page }) => {
                await page.goto(instance.consoleUrl);
                await page.waitForURL(`${instance.consoleUrl}/login`);
                await page.locator('input#accessKey').fill('test');
                await page.locator('input#secretKey').fill(getEnv(instance.url, 'TEST_PASSWORD'));
                await page.locator('button#do-login[type="submit"]').click();
                await page.waitForURL(`${instance.consoleUrl}/browser`);
                await expect(page.locator('#root .menuItems')).toBeVisible();
                await expect(page.locator('main.mainPage .page-header:has-text("Object Browser")')).toBeVisible();
            });

            test('UI: Unsuccessful login - Random user', async ({ page }) => {
                await page.goto(instance.consoleUrl);
                await page.waitForURL(`${instance.consoleUrl}/login`);
                const originalUrl = page.url();
                await page.locator('input#accessKey').fill(faker.string.alpha(10));
                await page.locator('input#secretKey').fill(faker.string.alpha(10));
                await page.locator('button#do-login[type="submit"]').click();
                await expect(page.locator('.messageTruncation:has-text("invalid Login.")')).toBeVisible();
                await expect(page, 'URL should not change').toHaveURL(originalUrl);
            });
        });
    }
});
