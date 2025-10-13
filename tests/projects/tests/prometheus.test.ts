import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { axios, getEnv } from '../../utils/utils';

test.describe(apps.prometheus.title, () => {
    for (const instance of apps.prometheus.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'basic' });
            createApiRootTest(instance.url, { title: 'Unauthenticated', status: 401 });
            createApiRootTest(instance.url, {
                title: 'Authenticated - User prometheus (unsuccessful)',
                headers: {
                    Authorization: `Basic ${Buffer.from(`prometheus:${getEnv(instance.url, 'PROMETHEUS_PASSWORD')}`).toString('base64')}`
                },
                status: 401,
            });
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            const validUsers = [
                {
                    username: 'homelab-viewer',
                },
                {
                    username: 'homelab-test',
                },
            ];
            for (const user of validUsers) {
                createApiRootTest(instance.url, {
                    title: `Authenticated - ${user.username}`,
                    headers: {
                        Authorization: `Basic ${Buffer.from(`${user.username}:${getEnv(instance.url, `${user.username}_PASSWORD`)}`).toString('base64')}`
                    },
                });

                test(`API: Successful get root - User ${user.username}`, async () => {
                    const response = await axios.get(instance.url, {
                        beforeRedirect: (opts) => {
                            opts['headers'] = {
                                Authorization: `Basic ${Buffer.from(`${user.username}:${getEnv(instance.url, `${user.username.toUpperCase()}_PASSWORD`)}`).toString('base64')}`,
                            };
                        },
                        headers: {
                            Authorization: `Basic ${Buffer.from(`${user.username}:${getEnv(instance.url, `${user.username.toUpperCase()}_PASSWORD`)}`).toString('base64')}`,
                        },
                    });
                    expect(response.status, 'Response Status').toStrictEqual(200);
                });

                test(`UI: Successful open - User ${user.username}`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${user.username}:${getEnv(instance.url, `${user.username.toUpperCase()}_PASSWORD`)}`).toString('base64')}` });
                    await page.goto(instance.url);
                    await expect(page.locator('#root header:has-text("Prometheus")')).toBeVisible({ timeout: 10_000 });
                    await expect(page.locator('#root header a:has-text("Query")')).toBeVisible();
                    await expect(page.locator('#root header a:has-text("Alerts")')).toBeVisible();
                    await expect(page.locator('#root header button:has-text("Status")')).toBeVisible();
                });
            }

            const invalidUsers = [
                {
                    username: 'matej',
                },
                {
                    username: 'prometheus',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                },
            ];
            for (const user of invalidUsers) {
                test(`API: Unsuccessful get root with bad password - ${user.random ? 'Random user' : `User ${user.username}`}`, async () => {
                    const response = await axios.get(instance.url, {
                        auth: {
                            username: user.username,
                            password: faker.string.alphanumeric(10),
                        },
                    });
                    expect(response.status, 'Response Status').toStrictEqual(401);
                });

                test(`API: Unsuccessful get root without password - ${user.random ? 'Random user' : `User ${user.username}`}`, async () => {
                    const response = await axios.get(instance.url, {
                        auth: {
                            username: user.username,
                            password: '',
                        },
                    });
                    expect(response.status, 'Response Status').toStrictEqual(401);
                });

                test(`UI: Unsuccessful open with bad password - ${user.random ? 'Random user' : `User ${user.username}`}`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${user.username}:${faker.string.alphanumeric(10)}`).toString('base64')}` });
                    await page.goto(instance.url);
                    await expect(page.locator('#root header:has-text("Prometheus")')).not.toBeVisible();
                });

                test(`UI: Unsuccessful open without password - ${user.random ? 'Random user' : `User ${user.username}`}`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${user.username}:`).toString('base64')}` });
                    await page.goto(instance.url);
                    await expect(page.locator('#root header:has-text("Prometheus")')).not.toBeVisible();
                });
            }

            test('API: Unsuccessful get root - No user', async () => {
                const response = await axios.get(instance.url);
                expect(response.status, 'Response Status').toStrictEqual(401);
            });

            test('UI: Unsuccessful open - No user', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('#root header:has-text("Prometheus")')).not.toBeVisible();
            });

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
                    'prometheus_api_notification_active_subscribers',
                    'prometheus_api_notification_updates_dropped_total',
                    'prometheus_api_notification_updates_sent_total',
                    'prometheus_build_info',
                    'prometheus_config_last_reload_success_timestamp_seconds',
                    'prometheus_config_last_reload_successful',
                    'prometheus_engine_queries',
                    'prometheus_engine_queries_concurrent_max',
                    'prometheus_engine_query_duration_seconds',
                    'prometheus_engine_query_duration_seconds_count',
                    'prometheus_engine_query_duration_seconds_sum',
                    'prometheus_engine_query_log_enabled',
                    'prometheus_engine_query_log_failures_total',
                    'prometheus_engine_query_samples_total',
                    'prometheus_http_request_duration_seconds_bucket',
                    'prometheus_http_request_duration_seconds_count',
                    'prometheus_http_request_duration_seconds_sum',
                    'prometheus_http_requests_total',
                    'prometheus_http_response_size_bytes_bucket',
                    'prometheus_http_response_size_bytes_count',
                    'prometheus_http_response_size_bytes_sum',
                    'prometheus_notifications_alertmanagers_discovered',
                    'prometheus_notifications_dropped_total',
                    'prometheus_notifications_queue_capacity',
                    'prometheus_notifications_queue_length',
                    'prometheus_ready',
                    'prometheus_remote_read_handler_queries',
                    'prometheus_remote_storage_exemplars_in_total',
                    'prometheus_remote_storage_highest_timestamp_in_seconds',
                    'prometheus_remote_storage_histograms_in_total',
                    'prometheus_remote_storage_samples_in_total',
                    'prometheus_remote_storage_string_interner_zero_reference_releases_total',
                    'prometheus_rule_evaluation_duration_seconds',
                    'prometheus_rule_evaluation_duration_seconds_count',
                    'prometheus_rule_evaluation_duration_seconds_sum',
                    'prometheus_rule_group_duration_seconds',
                    'prometheus_rule_group_duration_seconds_count',
                    'prometheus_rule_group_duration_seconds_sum',
                    'prometheus_sd_azure_cache_hit_total',
                    'prometheus_sd_azure_failures_total',
                    'prometheus_sd_consul_rpc_duration_seconds',
                    'prometheus_sd_consul_rpc_duration_seconds_count',
                    'prometheus_sd_consul_rpc_duration_seconds_sum',
                    'prometheus_sd_consul_rpc_failures_total',
                    'prometheus_sd_discovered_targets',
                    'prometheus_sd_dns_lookup_failures_total',
                    'prometheus_sd_dns_lookups_total',
                    'prometheus_sd_failed_configs',
                    'prometheus_sd_file_read_errors_total',
                    'prometheus_sd_file_scan_duration_seconds',
                    'prometheus_sd_file_scan_duration_seconds_count',
                    'prometheus_sd_file_scan_duration_seconds_sum',
                    'prometheus_sd_file_watcher_errors_total',
                    'prometheus_sd_http_failures_total',
                    'prometheus_sd_kubernetes_events_total',
                    'prometheus_sd_kubernetes_failures_total',
                    'prometheus_sd_kuma_fetch_duration_seconds',
                    'prometheus_sd_kuma_fetch_duration_seconds_count',
                    'prometheus_sd_kuma_fetch_duration_seconds_sum',
                    'prometheus_sd_kuma_fetch_failures_total',
                    'prometheus_sd_kuma_fetch_skipped_updates_total',
                    'prometheus_sd_linode_failures_total',
                    'prometheus_sd_nomad_failures_total',
                    'prometheus_sd_received_updates_total',
                    'prometheus_sd_updates_delayed_total',
                    'prometheus_sd_updates_total',
                    // 'prometheus_target_interval_length_seconds',
                    'prometheus_target_interval_length_seconds_count',
                    'prometheus_target_interval_length_seconds_sum',
                    'prometheus_target_metadata_cache_bytes',
                    'prometheus_target_metadata_cache_entries',
                    'prometheus_target_scrape_pool_exceeded_label_limits_total',
                    'prometheus_target_scrape_pool_exceeded_target_limit_total',
                    'prometheus_target_scrape_pool_reloads_failed_total',
                    'prometheus_target_scrape_pool_reloads_total',
                    'prometheus_target_scrape_pool_symboltable_items',
                    'prometheus_target_scrape_pool_sync_total',
                    'prometheus_target_scrape_pool_target_limit',
                    'prometheus_target_scrape_pool_targets',
                    'prometheus_target_scrape_pools_failed_total',
                    'prometheus_target_scrape_pools_total',
                    'prometheus_target_scrapes_cache_flush_forced_total',
                    'prometheus_target_scrapes_exceeded_body_size_limit_total',
                    'prometheus_target_scrapes_exceeded_native_histogram_bucket_limit_total',
                    'prometheus_target_scrapes_exceeded_sample_limit_total',
                    'prometheus_target_scrapes_exemplar_out_of_order_total',
                    'prometheus_target_scrapes_sample_duplicate_timestamp_total',
                    'prometheus_target_scrapes_sample_out_of_bounds_total',
                    'prometheus_target_scrapes_sample_out_of_order_total',
                    'prometheus_target_sync_failed_total',
                    'prometheus_target_sync_length_seconds',
                    'prometheus_target_sync_length_seconds_count',
                    'prometheus_target_sync_length_seconds_sum',
                    'prometheus_template_text_expansion_failures_total',
                    'prometheus_template_text_expansions_total',
                    'prometheus_treecache_watcher_goroutines',
                    'prometheus_treecache_zookeeper_failures_total',
                    'prometheus_tsdb_blocks_loaded',
                    'prometheus_tsdb_checkpoint_creations_failed_total',
                    'prometheus_tsdb_checkpoint_creations_total',
                    'prometheus_tsdb_checkpoint_deletions_failed_total',
                    'prometheus_tsdb_checkpoint_deletions_total',
                    'prometheus_tsdb_clean_start',
                    'prometheus_tsdb_compaction_chunk_range_seconds_bucket',
                    'prometheus_tsdb_compaction_chunk_range_seconds_count',
                    'prometheus_tsdb_compaction_chunk_range_seconds_sum',
                    'prometheus_tsdb_compaction_chunk_samples_bucket',
                    'prometheus_tsdb_compaction_chunk_samples_count',
                    'prometheus_tsdb_compaction_chunk_samples_sum',
                    'prometheus_tsdb_compaction_chunk_size_bytes_bucket',
                    'prometheus_tsdb_compaction_chunk_size_bytes_count',
                    'prometheus_tsdb_compaction_chunk_size_bytes_sum',
                    'prometheus_tsdb_compaction_duration_seconds_bucket',
                    'prometheus_tsdb_compaction_duration_seconds_count',
                    'prometheus_tsdb_compaction_duration_seconds_sum',
                    'prometheus_tsdb_compaction_populating_block',
                    'prometheus_tsdb_compactions_failed_total',
                    'prometheus_tsdb_compactions_skipped_total',
                    'prometheus_tsdb_compactions_total',
                    'prometheus_tsdb_compactions_triggered_total',
                    'prometheus_tsdb_data_replay_duration_seconds',
                    'prometheus_tsdb_exemplar_exemplars_appended_total',
                    'prometheus_tsdb_exemplar_exemplars_in_storage',
                    'prometheus_tsdb_exemplar_last_exemplars_timestamp_seconds',
                    'prometheus_tsdb_exemplar_max_exemplars',
                    'prometheus_tsdb_exemplar_out_of_order_exemplars_total',
                    'prometheus_tsdb_exemplar_series_with_exemplars_in_storage',
                    'prometheus_tsdb_head_active_appenders',
                    'prometheus_tsdb_head_chunks',
                    'prometheus_tsdb_head_chunks_created_total',
                    'prometheus_tsdb_head_chunks_removed_total',
                    'prometheus_tsdb_head_chunks_storage_size_bytes',
                    'prometheus_tsdb_head_gc_duration_seconds_count',
                    'prometheus_tsdb_head_gc_duration_seconds_sum',
                    'prometheus_tsdb_head_max_time',
                    'prometheus_tsdb_head_max_time_seconds',
                    'prometheus_tsdb_head_min_time',
                    'prometheus_tsdb_head_min_time_seconds',
                    'prometheus_tsdb_head_out_of_order_samples_appended_total',
                    'prometheus_tsdb_head_samples_appended_total',
                    'prometheus_tsdb_head_series',
                    'prometheus_tsdb_head_series_created_total',
                    'prometheus_tsdb_head_series_not_found_total',
                    'prometheus_tsdb_head_series_removed_total',
                    'prometheus_tsdb_head_truncations_failed_total',
                    'prometheus_tsdb_head_truncations_total',
                    'prometheus_tsdb_isolation_high_watermark',
                    'prometheus_tsdb_isolation_low_watermark',
                    'prometheus_tsdb_lowest_timestamp',
                    'prometheus_tsdb_lowest_timestamp_seconds',
                    'prometheus_tsdb_mmap_chunk_corruptions_total',
                    'prometheus_tsdb_mmap_chunks_total',
                    'prometheus_tsdb_out_of_bound_samples_total',
                    'prometheus_tsdb_out_of_order_samples_total',
                    'prometheus_tsdb_reloads_failures_total',
                    'prometheus_tsdb_reloads_total',
                    'prometheus_tsdb_retention_limit_bytes',
                    'prometheus_tsdb_retention_limit_seconds',
                    'prometheus_tsdb_size_retentions_total',
                    'prometheus_tsdb_snapshot_replay_error_total',
                    'prometheus_tsdb_storage_blocks_bytes',
                    'prometheus_tsdb_symbol_table_size_bytes',
                    'prometheus_tsdb_time_retentions_total',
                    'prometheus_tsdb_tombstone_cleanup_seconds_bucket',
                    'prometheus_tsdb_tombstone_cleanup_seconds_count',
                    'prometheus_tsdb_tombstone_cleanup_seconds_sum',
                    'prometheus_tsdb_too_old_samples_total',
                    'prometheus_tsdb_vertical_compactions_total',
                    'prometheus_tsdb_wal_completed_pages_total',
                    'prometheus_tsdb_wal_corruptions_total',
                    'prometheus_tsdb_wal_fsync_duration_seconds',
                    'prometheus_tsdb_wal_fsync_duration_seconds_count',
                    'prometheus_tsdb_wal_fsync_duration_seconds_sum',
                    'prometheus_tsdb_wal_page_flushes_total',
                    'prometheus_tsdb_wal_segment_current',
                    'prometheus_tsdb_wal_storage_size_bytes',
                    'prometheus_tsdb_wal_truncate_duration_seconds_count',
                    'prometheus_tsdb_wal_truncate_duration_seconds_sum',
                    'prometheus_tsdb_wal_truncations_failed_total',
                    'prometheus_tsdb_wal_truncations_total',
                    'prometheus_tsdb_wal_writes_failed_total',
                    'prometheus_web_federation_errors_total',
                    'prometheus_web_federation_warnings_total',
                ];
                for (const metric of metrics) {
                    expect(lines.find((el) => el.startsWith(metric)), `Metric ${metric}`).toBeDefined();
                }
            });
        });
    }
});
