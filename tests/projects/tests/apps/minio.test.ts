import https from 'node:https';
import UserAgent from 'user-agents';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { getEnv } from '../../../utils/utils';
import { apps } from '../../../utils/apps';
import { createHttpToHttpsRedirectTests, createTcpTest } from '../../../utils/tests';

test.describe(apps.minio.title, () => {
    for (const instance of apps.minio.instances) {
        test.describe(instance.title, () => {
            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
                createTcpTest(instance.consoleUrl, port, 'console');
            }

            createHttpToHttpsRedirectTests(instance.url);

            const users = [
                {
                    username: 'admin',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                }
            ];
            for (const variant of users) {
                if (!variant.random) {
                    test(`UI: Successful login - User ${variant.username}`, async ({ page }) => {
                        await page.goto(instance.consoleUrl);
                        await page.waitForURL(`${instance.consoleUrl}/login`);
                        await page.locator('input#accessKey').fill(variant.username);
                        await page.locator('input#secretKey').fill(getEnv(instance.url, `${variant.username.toUpperCase()}_PASSWORD`));
                        await page.locator('button#do-login[type=submit]').click();
                        await page.waitForURL(`${instance.consoleUrl}/browser`);
                    });
                }

                test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.goto(instance.consoleUrl);
                    await page.waitForURL(`${instance.consoleUrl}/login`);
                    const originalUrl = page.url();
                    await page.locator('input#accessKey').fill(variant.username);
                    await page.locator('input#secretKey').fill(faker.string.alpha(10));
                    await page.locator('button#do-login[type=submit]').click();
                    await expect(page.locator('.messageTruncation:has-text("invalid Login.")')).toBeVisible();
                    expect(page.url(), 'URL should not change').toStrictEqual(originalUrl);
                });
            }

            test('API: Root', async () => {
                const userAgent = new UserAgent([/Chrome/, { platform: 'Win32', vendor: 'Google Inc.' }]).toString();
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999, headers: { 'User-Agent': userAgent }, validateStatus: () => true});
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Redirect to console', async () => {
                const userAgent = new UserAgent([/Chrome/, { platform: 'Win32', vendor: 'Google Inc.' }]).toString();
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, headers: { 'User-Agent': userAgent }, validateStatus: () => true });
                expect(response.status, 'Response Status').toStrictEqual(307);
                expect(response.headers['location'], 'Response header location').toStrictEqual(instance.consoleUrl);
            });

            test('API: Console root', async () => {
                const response = await axios.get(instance.consoleUrl, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Health endpoint (live)', async () => {
                const response = await axios.get(`${instance.url}/minio/health/live`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Health endpoint (cluster)', async () => {
                const response = await axios.get(`${instance.url}/minio/health/cluster`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Health endpoint (cluster-read)', async () => {
                const response = await axios.get(`${instance.url}/minio/health/cluster/read`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            const prometheusVariants = [
                {
                    title: 'missing credentials',
                    auth: undefined as unknown as { username: string, password: string },
                    status: 403,
                },
                {
                    title: 'wrong credentials',
                    auth: faker.internet.jwt(),
                    status: 403,
                },
                {
                    title: 'successful',
                    auth: getEnv(instance.url, 'PROMETHEUS_BEARER_TOKEN'),
                    status: 200,
                },
            ];
            for (const variant of prometheusVariants) {
                test(`API: Prometheus metrics (${variant.title})`, async () => {
                    const headers: Record<string, string> = {};
                    if (variant.auth) {
                        headers['Authorization'] = `Bearer ${variant.auth}`;
                    }

                    const response = await axios.get(`${instance.url}/minio/v2/metrics/cluster`, {
                        headers: headers,
                        maxRedirects: 999,
                        validateStatus: () => true,
                        httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                    });
                    expect(response.status, 'Response Status').toStrictEqual(variant.status);
                });
            }

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
        });
    }
});
