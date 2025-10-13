import fsx from 'node:fs/promises';
import nodeDns from 'node:dns/promises';
import path from 'node:path';
import _ from 'lodash';
import { expect, test } from '@playwright/test';
import { axios, dnsLookup, getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { faker } from '@faker-js/faker';

test.describe(apps.unbound.title, () => {
    for (const instance of apps.unbound.instances) {
        test.describe(instance.title, () => {
            // Get domain for DNS server for a given variant
            const instanceDomain = instance.url.replace(/^https?:\/\//, '');

            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'basic' });
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [53, 80, 443]);
            createFaviconTests(instance.url);

            const prometheusUsers = [
                {
                    username: 'matej'
                },
                {
                    username: 'homelab-viewer'
                },
                {
                    username: 'homelab-test'
                },
                {
                    username: 'prometheus'
                },
            ];
            for (const user of prometheusUsers) {
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

            const invalidPrometheusUsers = [
                {
                    username: 'homelab-test'
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                },
            ];
            for (const user of invalidPrometheusUsers) {
                test(`API: Unsuccessful get prometheus metrics with bad password - ${user.random ? 'Random user' : `User ${user.username}`}`, async () => {
                    const response = await axios.get(`${instance.url}/metrics`, {
                        auth: {
                            username: user.username,
                            password: faker.string.alphanumeric(10),
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

            test('DNS: example.com lookup', async () => {
                const instanceIp = await (async () => {
                    const instancesIps = await nodeDns.resolve(instanceDomain);
                    expect(instancesIps, 'Unbound DNS address resolution').toHaveLength(1);
                    return instancesIps[0];
                })();

                for (const transportVariant of ['tcp', 'udp'] as const) {
                    for (const ipVariant of ['A', 'AAAA'] as const) {
                        await test.step(`Check example.com via ${transportVariant.toUpperCase()} ${ipVariant}`, async () => {
                            const ips = await dnsLookup('example.com', transportVariant, ipVariant, instanceIp);
                            expect(ips, 'Domain should be resolved').not.toHaveLength(0);
                            for (const ip of ips) {
                                switch (ipVariant) {
                                    case 'A': {
                                        expect(ip, 'Resolved entry should be valid IPv4').toMatch(/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/);
                                        expect(ip, 'Resolved entry should not be 0.0.0.0').not.toStrictEqual('0.0.0.0');
                                        expect(ip, 'Resolved entry should not be localhost').not.toStrictEqual(/^127\./);
                                        expect(ip, 'Resolved entry should not be in private range').not.toMatch(/^10\./);
                                        expect(ip, 'Resolved entry should not be in private range').not.toMatch(/^172\.(1[6-9]|2[0-9]|3[0-1])\./);
                                        expect(ip, 'Resolved entry should not be in private range').not.toMatch(/^192\.168\./);
                                        break;
                                    }
                                    case 'AAAA': {
                                        expect(ip, 'Resolved entry should be valid IPv6').toMatch(/([0-9a-f]{1,4}:){7}[0-9a-f]{1,4}/);
                                        expect(ip, 'Resolved entry should not be localhost').not.toStrictEqual('::1');
                                        expect(ip, 'Resolved entry should not be in private range').not.toMatch(/^f[cd][0-9a-fA-F][0-9a-fA-F]:/);
                                        break;
                                    }
                                }
                            }
                        });
                    }
                }
            });

            test('DNS: self domain', async () => {
                const instanceIp = await (async () => {
                    const instancesIps = await nodeDns.resolve(instanceDomain);
                    expect(instancesIps, 'Unbound DNS address resolution').toHaveLength(1);
                    return instancesIps[0];
                })();

                for (const transportVariant of ['tcp', 'udp'] as const) {
                    for (const ipVariant of ['A', 'AAAA'] as const) {
                        await test.step(`Check self via ${transportVariant.toUpperCase()} ${ipVariant}`, async () => {
                            const ips = await dnsLookup(instanceDomain, transportVariant, ipVariant, instanceIp);
                            switch (ipVariant) {
                            case 'A': {
                                expect(ips, 'Domain should be resolved').not.toHaveLength(0);
                                expect(ips, 'Domain should be resolved exactly').toContain(instanceIp);
                                break;
                            }
                            case 'AAAA': {
                                expect(ips, 'Domain should not be resolved').toHaveLength(0);
                                break;
                            }
                        }
                        });
                    }
                }
            });

            test('DNS: local unused domain', async () => {
                const instanceIp = await (async () => {
                    const instancesIps = await nodeDns.resolve(instanceDomain);
                    expect(instancesIps, 'Unbound DNS address resolution').toHaveLength(1);
                    return instancesIps[0];
                })();

                for (const transportVariant of ['tcp', 'udp'] as const) {
                    for (const ipVariant of ['A', 'AAAA'] as const) {
                        await test.step(`Check <random>.matejhome.com via ${transportVariant.toUpperCase()} ${ipVariant}`, async () => {
                            const ips = await dnsLookup(`${faker.string.alpha(10)}.matejhome.com`, transportVariant, ipVariant, instanceIp);
                            expect(ips, 'Domain should not be resolved').toHaveLength(0);
                        });
                    }
                }
            });

            test('DNS: Local domains lookup', async () => {
                const instanceIp = await (async () => {
                    const instanceIps = await nodeDns.resolve(instanceDomain);
                    expect(instanceIps, 'Unbound DNS address resolution').toHaveLength(1);
                    return instanceIps[0];
                })();

                const customDomainsPath = path.join('..', 'docker-images', 'external', 'pihole', 'custom-domains.txt');
                const domains: { ip: string, domain: string }[] = (await fsx.readFile(customDomainsPath, 'utf-8'))
                    .split('\n')
                    .map((line: string) => line.replace(/#.*$/, '').trim())
                    .filter((line: string) => line !== '')
                    .map((line: string) => ({ ip: line.split(/\s+/)[0], domain: line.split(/\s+/)[1] }));

                for (const entry of domains) {
                    for (const transportVariant of ['tcp', 'udp'] as const) {
                        await test.step(`Check domain ${entry.domain} via ${transportVariant.toUpperCase()}`, async () => {
                            const ipType = entry.ip.includes('.') ? 'A' : 'AAAA';
                            const ips = await dnsLookup(entry.domain, transportVariant, ipType, instanceIp);
                            expect(ips, 'Domain should be resolved').not.toHaveLength(0);
                            expect(ips, `Domain ${entry.ip} should be resolved to IP address`).toContain(entry.ip);
                        });
                    }
                }
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
