import _ from 'lodash';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { axios, getEnv } from '../../utils/utils';

test.describe(apps.samba.title, () => {
    for (const instance of apps.samba.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url.replace(/^smb:\/\//, 'https://'));
            createProxyTests(instance.url.replace(/^smb:\/\//, 'https://'));
            createApiRootTest(instance.url.replace(/^smb:\/\//, 'https://'));
            createTcpTests(instance.url.replace(/^smb:\/\//, 'https://'), [80, 139, 443, 445]);
            createFaviconTests(instance.url.replace(/^smb:\/\//, 'https://'));
            createPrometheusTests(instance.url.replace(/^smb:\/\//, 'https://'), { auth: 'basic' });

            test('API: Prometheus metrics content', async () => {
                const response = await axios.get(`${instance.url.replace(/^smb:\/\//, 'https://')}/metrics`, {
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
                    'samba_client_count',
                    'samba_exporter_information',
                    'samba_individual_user_count',
                    'samba_locked_file_count',
                    'samba_pid_count',
                    'samba_request_time',
                    'samba_satutsd_up',
                    'samba_server_up',
                    'samba_share_count',
                    'samba_smbd_cpu_usage_percentage',
                    'samba_smbd_io_counter_read_bytes',
                    'samba_smbd_io_counter_read_count',
                    'samba_smbd_io_counter_write_bytes',
                    'samba_smbd_io_counter_write_count',
                    'samba_smbd_open_file_count',
                    'samba_smbd_sum_cpu_usage_percentage',
                    'samba_smbd_sum_io_counter_read_bytes',
                    'samba_smbd_sum_io_counter_read_count',
                    'samba_smbd_sum_io_counter_write_bytes',
                    'samba_smbd_sum_io_counter_write_count',
                    'samba_smbd_sum_open_file_count',
                    'samba_smbd_sum_thread_count',
                    'samba_smbd_sum_virtual_memory_usage_bytes',
                    'samba_smbd_sum_virtual_memory_usage_percent',
                    'samba_smbd_thread_count',
                    'samba_smbd_unique_process_id_count',
                    'samba_smbd_virtual_memory_usage_bytes',
                    'samba_smbd_virtual_memory_usage_percent',
                ];
                for (const metric of metrics) {
                    expect(lines.find((el) => el.startsWith(metric)), `Metric ${metric}`).toBeDefined();
                }
            });
        });
    }
});
