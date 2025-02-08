import https from 'node:https';
import axios from 'axios';
import { expect, test } from '@playwright/test';
import { faker } from '@faker-js/faker';
import { dnsLookup, getEnv } from '../../../utils/utils';
import { apps } from '../../../utils/apps';
import _ from 'lodash';
import nodeDns from 'node:dns/promises';

test.describe(apps.pihole.title, () => {
    for (const instance of apps.pihole.instances) {
        test.describe(instance.title, () => {
            test('UI: Successful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/admin/login.php`);
                await page.locator('form#loginform input#loginpw').fill(getEnv(instance.url, 'PASSWORD'));
                await page.locator('form#loginform button[type=submit]').click();
                await page.waitForURL(/\/admin(?:\/?|\/index\.php)$/);
            });

            test('UI: Unsuccessful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/admin/login.php`);
                await page.locator('form#loginform input#loginpw').fill(faker.string.alpha(10));
                await page.locator('form#loginform button[type=submit]').click();
                await page.waitForSelector('.login-box-msg.has-error >> text="Wrong password!"', { timeout: 10_000 });
                expect(page.url()).toStrictEqual(`${instance.url}/admin/login.php`);
            });

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            const proxyStatusVariants = [
                {
                    title: 'missing credentials',
                    auth: undefined as unknown as { username: string, password: string },
                    status: 401,
                },
                {
                    title: 'wrong credentials',
                    auth: {
                        username: 'proxy-status',
                        password: faker.string.alphanumeric(10),
                    },
                    status: 401,
                },
                {
                    title: 'successful',
                    auth: {
                        username: 'proxy-status',
                        password: getEnv(instance.url, 'PROXY_STATUS_PASSWORD'),
                    },
                    status: 200,
                },
            ];
            for (const variant of proxyStatusVariants) {
                test(`API: Proxy status (${variant.title})`, async () => {
                    const response = await axios.get(`${instance.url}/.proxy/status`, {
                        auth: variant.auth,
                        maxRedirects: 999,
                        validateStatus: () => true,
                        httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                    });
                    expect(response.status, 'Response Status').toStrictEqual(variant.status);
                });
            }

            for (const transportVariant of ['tcp', 'udp'] as const) {
                test(`DNS: ${transportVariant.toUpperCase()}`, async () => {
                    // Get domain for DNS server for a given variant
                    const piholeDnsDomain = instance.url.replace(/^https?:\/\//, '');

                    // Get IP address
                    const piholeDnsIps = await nodeDns.resolve(piholeDnsDomain);
                    expect(piholeDnsIps, 'Pihole DNS address resolution').toHaveLength(1);

                    // Resolved external domain
                    const ips = await dnsLookup('example.com', transportVariant, 'A', piholeDnsIps[0]);
                    expect(ips, 'Domain should be resolved').not.toHaveLength(0);
                });
            }
        });
    }
});
