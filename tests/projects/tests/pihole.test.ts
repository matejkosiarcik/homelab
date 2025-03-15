import nodeDns from 'node:dns/promises';
import _ from 'lodash';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { axios, dnsLookup, getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createApiRootTest, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps.pihole.title, () => {
    for (const instance of apps.pihole.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'basic' });
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [53, 80, 443]);

            for (const transportVariant of ['tcp', 'udp'] as const) {
                for (const ipVariant of ['A', 'AAAA'] as const) {
                    test(`DNS: ${transportVariant.toUpperCase()} ${ipVariant}`, async () => {
                        // Get domain for DNS server for a given variant
                        const piholeDnsDomain = instance.url.replace(/^https?:\/\//, '');

                        // Get IP address
                        const piholeDnsIps = await nodeDns.resolve(piholeDnsDomain);
                        expect(piholeDnsIps, 'Pihole DNS address resolution').toHaveLength(1);

                        // Resolved external domain
                        const ips = await dnsLookup('example.com', transportVariant, ipVariant, piholeDnsIps[0]);
                        expect(ips, 'Domain should be resolved').not.toHaveLength(0);
                        expect(ips[0], `Resolved domain should be IPv${ipVariant === 'A' ? '4' : '6'}`).toMatch(ipVariant === 'A' ? /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ : /([0-9a-f]{1,4}:){7}[0-9a-f]{1,4}/);
                    });
                }
            }

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
