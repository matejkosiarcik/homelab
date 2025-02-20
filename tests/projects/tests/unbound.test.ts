import nodeDns from 'node:dns/promises';
import https from 'node:https';
import _ from 'lodash';
import { expect, test } from '@playwright/test';
import { dnsLookup, getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createHttpToHttpsRedirectTests, createProxyStatusTests, createTcpTest } from '../../utils/tests';
import { faker } from '@faker-js/faker';
import axios from 'axios';

test.describe(apps.unbound.title, () => {
    for (const instance of apps.unbound.instances) {
        test.describe(instance.title, () => {
            for (const port of [53, 80, 443]) {
                createTcpTest(instance.url, port);
            }

            createHttpToHttpsRedirectTests(instance.url);
            createProxyStatusTests(instance.url);


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
                expect(lines.find((el) => el.startsWith('unbound_query_flags_total'))).toBeDefined();
                expect(lines.find((el) => el.startsWith('unbound_query_types_total'))).toBeDefined();
                expect(lines.find((el) => el.startsWith('unbound_response_time_seconds_bucket'))).toBeDefined();
                expect(lines.find((el) => el.startsWith('unbound_time_up_seconds_total'))).toBeDefined();
            });
        });
    }
});
