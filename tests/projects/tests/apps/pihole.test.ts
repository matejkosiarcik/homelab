import nodeDns from 'node:dns/promises';
import https from 'node:https';
import axios from 'axios';
import _ from 'lodash';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { dnsLookup, getEnv } from '../../../utils/utils';
import { apps } from '../../../utils/apps';
import { createHttpToHttpsRedirectTests, createProxyStatusTests, createTcpTest } from '../../../utils/tests';

test.describe(apps.pihole.title, () => {
    for (const instance of apps.pihole.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyStatusTests(instance.url);

            for (const port of [53, 80, 443]) {
                createTcpTest(instance.url, port);
            }

            test('UI: Successful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/admin/login.php`);
                await page.locator('form#loginform input#loginpw').fill(getEnv(instance.url, 'PASSWORD'));
                await page.locator('form#loginform button[type="submit"]').click();
                await page.waitForURL(/\/admin(?:\/?|\/index\.php)$/);
            });

            test('UI: Unsuccessful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/admin/login.php`);
                await page.locator('form#loginform input#loginpw').fill(faker.string.alpha(10));
                await page.locator('form#loginform button[type="submit"]').click();
                await page.waitForSelector('.login-box-msg.has-error >> text="Wrong password!"', { timeout: 10_000 });
                expect(page.url()).toStrictEqual(`${instance.url}/admin/login.php`);
            });

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

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
        });
    }
});
