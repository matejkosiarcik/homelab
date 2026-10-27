import nodeDns from 'node:dns/promises';
import _ from 'lodash';
import { faker } from '@faker-js/faker';
import { expect, test } from '#/playwright/test.ts';
import { axios, dnsLookup, getAllHomelabDomains, getEnv } from '#/utils/utils.ts';
import { apps } from '#/utils/apps.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createHttpsRootRedirectTest, createPrometheusTests, createProxyTests, createTcpTests } from '#/utils/tests.ts';

const app = apps.pihole;

test.describe(app.title, () => {
    for (const instance of app.instances) {
        if ('enabled' in instance && instance.enabled === false) {
            test.skip(`Instance ${app.title} ${instance.title} is disabled`, () => {});
            continue;
        }

        test.describe(instance.title, () => {
            // Get domain for DNS server for a given variant
            const instanceDomain = instance.url.replace(/^https?:\/\//, '');

            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'basic' });
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [53, 80, 443]);
            createFaviconTests(instance.url);
            createHttpsRootRedirectTest(instance.url, '/admin');

            test('DNS: example.com lookup', { lock: 'dns' }, async () => {
                const instanceIp = await (async () => {
                    const instancesIps = await nodeDns.resolve(instanceDomain);
                    expect(instancesIps, 'PiHole DNS address resolution').toHaveLength(1);
                    return instancesIps[0];
                })();

                for (const transportVariant of ['tcp', 'udp'] as const) {
                    for (const ipVariant of ['A', 'AAAA'] as const) {
                        await test.step.soft(`Check example.com via ${transportVariant.toUpperCase()} ${ipVariant}`, async () => {
                            const ips = await dnsLookup('example.com', transportVariant, ipVariant, instanceIp);
                            expect(ips, `Domain example.com should be resolved`).not.toHaveLength(0);
                            for (const ip of ips) {
                                switch (ipVariant) {
                                    case 'A': {
                                        expect(ip, 'Resolved entry should be valid IPv4').toMatch(/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/);
                                        expect(ip, 'Resolved entry should not be 0.0.0.0').not.toStrictEqual('0.0.0.0');
                                        expect(ip, 'Resolved entry should not be localhost').not.toStrictEqual(/^127\./);
                                        expect(ip, 'Resolved entry should not be in private range').not.toMatch(/^10\./);
                                        expect(ip, 'Resolved entry should not be in private range').not.toMatch(/^172\.(?:1[6-9]|2[0-9]|3[0-1])\./);
                                        expect(ip, 'Resolved entry should not be in private range').not.toMatch(/^192\.168\./);
                                        break;
                                    }
                                    case 'AAAA': {
                                        expect(ip, 'Resolved entry should be valid IPv6').toMatch(/(?:[0-9a-f]{1,4}:){7}[0-9a-f]{1,4}/);
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

            test('DNS: self domain lookup', { lock: 'dns' }, async () => {
                const instanceIp = await (async () => {
                    const instancesIps = await nodeDns.resolve(instanceDomain);
                    expect(instancesIps, 'PiHole DNS address resolution').toHaveLength(1);
                    return instancesIps[0];
                })();

                for (const transportVariant of ['tcp', 'udp'] as const) {
                    for (const ipVariant of ['A', 'AAAA'] as const) {
                        await test.step.soft(`Check self via ${transportVariant.toUpperCase()} ${ipVariant}`, async () => {
                            const ips = await dnsLookup(instanceDomain, transportVariant, ipVariant, instanceIp);
                            switch (ipVariant) {
                                case 'A': {
                                    expect(ips, `Domain ${instanceDomain} should be resolved`).not.toHaveLength(0);
                                    expect(ips, `Domain ${instanceDomain} should be resolved exactly`).toContain(instanceIp);
                                    break;
                                }
                                case 'AAAA': {
                                    expect(ips, `Domain ${instanceDomain} should not be resolved`).toHaveLength(0);
                                    break;
                                }
                            }
                        });
                    }
                }
            });

            test('DNS: local unused domain', { lock: 'dns' }, async () => {
                const instanceIp = await (async () => {
                    const instancesIps = await nodeDns.resolve(instanceDomain);
                    expect(instancesIps, 'PiHole DNS address resolution').toHaveLength(1);
                    return instancesIps[0];
                })();

                for (const transportVariant of ['tcp', 'udp'] as const) {
                    for (const ipVariant of ['A', 'AAAA'] as const) {
                        await test.step.soft(`Check <random>.matejhome.com via ${transportVariant.toUpperCase()} ${ipVariant}`, async () => {
                            const domain = `${faker.string.alpha(10)}.matejhome.com`;
                            const ips = await dnsLookup(domain, transportVariant, ipVariant, instanceIp);
                            expect(ips, 'Domain should not be resolved').toHaveLength(0);
                        });
                    }
                }
            });

            test('DNS: Local domains lookup', { lock: 'dns' }, async () => {
                const instanceIp = await (async () => {
                    const instanceIps = await nodeDns.resolve(instanceDomain);
                    expect(instanceIps, 'PiHole DNS address resolution').toHaveLength(1);
                    return instanceIps[0];
                })();

                const domains = getAllHomelabDomains();

                for (const domain of domains) {
                    for (const transportVariant of ['tcp', 'udp'] as const) {
                        await test.step.soft(`Check domain ${domain} via ${transportVariant.toUpperCase()}`, async () => {
                            const ips = await dnsLookup(domain, transportVariant, 'A', instanceIp);
                            expect(ips, `Domain ${domain} should be resolved`).not.toHaveLength(0);
                            for (const ip of ips) {
                                expect(ip, `Resolved entry should be valid IPv4`).toMatch(/^10\.1\.\d{1,3}\.\d{1,3}$/);
                            }
                        });
                    }
                }
            });

            test('API: Prometheus metrics content', async () => {
                const response = await test.step('Request server', async () => {
                    const response = await axios.get(`${instance.url}/metrics`, {
                        auth: {
                            username: 'prometheus',
                            password: getEnv(instance.url, 'PROMETHEUS_PASSWORD'),
                        },
                        timeout: 15_000,
                    });
                    expect(response.status, 'Response Status').toStrictEqual(200);
                    return response;
                });

                await test.step('Validate response', async () => {
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
            });

            test('UI: Successful login', async ({ page }) => {
                await test.step('Open login', async () => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/admin/login`);
                });

                await test.step('Login', async () => {
                    await page.locator('form#loginform input[type="password"]').fill(getEnv(instance.url, 'PASSWORD'));
                    await page.locator('form#loginform button[type="submit"]').click({ noWaitAfter: true, timeout: 5000 });
                });

                await test.step('Validate login', async () => {
                    await page.waitForURL(/\/admin(?:\/?|\/index\.php)$/);
                    await expect(page.locator('aside.main-sidebar li a:has-text("Dashboard")')).toBeVisible();
                    await expect(page.locator('.content-wrapper #total_queries')).toBeVisible();
                    await expect(page.locator('.content-wrapper #queries-over-time')).toBeVisible();
                });
            });

            test('UI: Unsuccessful login', async ({ page }) => {
                const originalUrl = await test.step('Open login', async () => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/admin/login`);
                    return page.url();
                });

                await test.step('Attempt login', async () => {
                    await page.locator('form#loginform input[type="password"]').fill(faker.string.alpha(10));
                    await page.locator('form#loginform button[type="submit"]').click();
                });

                await test.step('Validate login attempt', async () => {
                    await page.waitForSelector('#error-message:has-text("Wrong password!")', { timeout: 10_000 });
                    await expect(page, 'URL should not change').toHaveURL(originalUrl);
                });
            });
        });
    }
});
