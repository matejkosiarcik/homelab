import nodeDns from 'node:dns/promises';
import https from 'node:https';
import _ from 'lodash';
import { expect, test } from '@playwright/test';
import { dnsLookup, getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createHttpToHttpsRedirectTests, createProxyTests, createTcpTest } from '../../utils/tests';
import { faker } from '@faker-js/faker';
import axios from 'axios';

test.describe(apps.unbound.title, () => {
    for (const instance of apps.unbound.instances) {
        test.describe(instance.title, () => {
            for (const port of [53, 80, 443]) {
                createTcpTest(instance.url, port);
            }

            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);


            for (const transportVariant of ['tcp', 'udp'] as const) {
                for (const ipVariant of ['A', 'AAAA'] as const) {
                    test(`DNS: ${transportVariant.toUpperCase()} ${ipVariant}`, async () => {
                        // Get domain for DNS server for a given variant
                        const unboundDnsDomain = instance.url.replace(/^https?:\/\//, '');

                        // Get IP address
                        const unboundDnsIps = await nodeDns.resolve(unboundDnsDomain);
                        expect(unboundDnsIps, 'Pihole DNS address resolution').toHaveLength(1);

                        // Resolve external domain
                        const ips = await dnsLookup('example.com', transportVariant, ipVariant, unboundDnsIps[0]);
                        expect(ips, 'Domain should be resolved').not.toHaveLength(0);
                        expect(ips[0], `Resolved domain should be IPv${ipVariant === 'A' ? '4' : '6'}`).toMatch(ipVariant === 'A' ? /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ : /([0-9a-f]{1,4}:){7}[0-9a-f]{1,4}/);
                    });
                }
            }

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999, validateStatus: () => true });
                expect(response.status, 'Response Status').toStrictEqual(404);
            });

            const prometheusVariants = [
                {
                    title: 'no credentials',
                    auth: undefined as unknown as { username: string, password: string },
                    status: 401,
                },
                {
                    title: 'wrong username and password',
                    auth: {
                        username: faker.string.alphanumeric(10),
                        password: faker.string.alphanumeric(10),
                    },
                    status: 401,
                },
                {
                    title: 'wrong password',
                    auth: {
                        username: 'prometheus',
                        password: faker.string.alphanumeric(10),
                    },
                    status: 401,
                },
                {
                    title: 'successful',
                    auth: {
                        username: 'prometheus',
                        password: getEnv(instance.url, 'PROMETHEUS_PASSWORD'),
                    },
                    status: 200,
                },
            ];
            for (const variant of prometheusVariants) {
                test(`API: Prometheus metrics (${variant.title})`, async () => {
                    const response = await axios.get(`${instance.url}/metrics`, {
                        auth: variant.auth,
                        maxRedirects: 999,
                        validateStatus: () => true,
                        httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                    });
                    expect(response.status, 'Response Status').toStrictEqual(variant.status);
                });
            }

            test('API: Prometheus metrics content', async () => {
                const response = await axios.get(`${instance.url}/metrics`, {
                    auth: {
                        username: 'prometheus',
                        password: getEnv(instance.url, 'PROMETHEUS_PASSWORD'),
                    },
                    maxRedirects: 999,
                    validateStatus: () => true,
                    httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
                const content = response.data as string;
                const lines = content.split('\n');
                const metrics = [
                    'unbound_answer_rcodes_total',
                    'unbound_answers_bogus',
                    'unbound_answers_secure_total',
                    'unbound_cache_hits_total',
                    'unbound_cache_misses_total',
                    'unbound_expired_total',
                    'unbound_memory_caches_bytes',
                    'unbound_memory_doh_bytes',
                    'unbound_memory_modules_bytes',
                    'unbound_msg_cache_count',
                    'unbound_prefetches_total',
                    'unbound_queries_total',
                    'unbound_query_aggressive_nsec',
                    'unbound_query_classes_total',
                    'unbound_query_edns_DO_total',
                    'unbound_query_edns_present_total',
                    'unbound_query_flags_total',
                    'unbound_query_https_total',
                    'unbound_query_ipv6_total',
                    'unbound_query_opcodes_total',
                    'unbound_query_tcp_total',
                    'unbound_query_tcpout_total',
                    'unbound_query_tls_resume_total',
                    'unbound_query_tls_total',
                    'unbound_query_types_total',
                    'unbound_query_udpout_total',
                    'unbound_recursion_time_seconds_avg',
                    'unbound_recursion_time_seconds_median',
                    'unbound_recursive_replies_total',
                    'unbound_request_list_current_all',
                    'unbound_request_list_current_user',
                    'unbound_request_list_exceeded_total',
                    'unbound_request_list_overwritten_total',
                    'unbound_response_time_seconds_bucket',
                    'unbound_response_time_seconds_count',
                    'unbound_response_time_seconds_sum',
                    'unbound_rrset_bogus_total',
                    'unbound_rrset_cache_count',
                    'unbound_time_elapsed_seconds',
                    'unbound_time_now_seconds',
                    'unbound_time_up_seconds_total',
                    'unbound_unwanted_queries_total',
                    'unbound_unwanted_replies_total',
                    'unbound_up',
                ];
                for (const metric of metrics) {
                    expect(lines.find((el) => el.startsWith(metric)), `Metric ${metric}`).toBeDefined();
                }
            });
        });
    }
});
