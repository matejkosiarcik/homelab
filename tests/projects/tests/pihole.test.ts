import fsx from 'node:fs/promises';
import nodeDns from 'node:dns/promises';
import path from 'node:path';
import _ from 'lodash';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { axios, dnsLookup, getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps.pihole.title, () => {
    for (const instance of apps.pihole.instances) {
        test.describe(instance.title, () => {
            // Get domain for DNS server for a given variant
            const instanceDomain = instance.url.replace(/^https?:\/\//, '');

            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'basic' });
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [53, 80, 443]);
            createFaviconTests(instance.url);

            test('DNS: example.com lookup', async () => {
                const instanceIp = await (async () => {
                    const instancesIps = await nodeDns.resolve(instanceDomain);
                    expect(instancesIps, 'PiHole DNS address resolution').toHaveLength(1);
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

            test('DNS: self lookup', async () => {
                const instanceIp = await (async () => {
                    const instancesIps = await nodeDns.resolve(instanceDomain);
                    expect(instancesIps, 'PiHole DNS address resolution').toHaveLength(1);
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
                    expect(instancesIps, 'PiHole DNS address resolution').toHaveLength(1);
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
                    expect(instanceIps, 'PiHole DNS address resolution').toHaveLength(1);
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
                    'pihole_ads_blocked_today',
                    'pihole_ads_percentage_today',
                    'pihole_clients_ever_seen',
                    'pihole_dns_queries_all_types',
                    'pihole_dns_queries_today',
                    'pihole_domains_being_blocked',
                    'pihole_forward_destinations',
                    'pihole_queries_cached',
                    'pihole_queries_forwarded',
                    'pihole_querytypes',
                    'pihole_reply',
                    'pihole_status',
                    'pihole_top_ads',
                    'pihole_top_queries',
                    'pihole_top_sources',
                    'pihole_unique_clients',
                    'pihole_unique_domains',
                ];
                for (const metric of metrics) {
                    expect(lines.find((el) => el.startsWith(metric)), `Metric ${metric}`).toBeDefined();
                }
            });

            test('UI: Successful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/admin/login`);
                await page.locator('form#loginform input[type="password"]').fill(getEnv(instance.url, 'PASSWORD'));
                await page.locator('form#loginform button[type="submit"]').click({ timeout: 5000 });
                await page.waitForURL(/\/admin(?:\/?|\/index\.php)$/);
                await expect(page.locator('aside.main-sidebar li a:has-text("Dashboard")')).toBeVisible();
                await expect(page.locator('.content-wrapper #total_queries')).toBeVisible();
                await expect(page.locator('.content-wrapper #queries-over-time')).toBeVisible();
            });

            test('UI: Unsuccessful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/admin/login`);
                const originalUrl = page.url();
                await page.locator('form#loginform input[type="password"]').fill(faker.string.alpha(10));
                await page.locator('form#loginform button[type="submit"]').click();
                await page.waitForSelector('#error-message:has-text("Wrong password!")', { timeout: 10_000 });
                await expect(page, 'URL should not change').toHaveURL(originalUrl);
            });
        });
    }
});
