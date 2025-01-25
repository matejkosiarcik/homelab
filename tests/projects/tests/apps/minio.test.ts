import https from 'node:https';
import axios from 'axios';
import UserAgent from 'user-agents';
import { expect, test } from '@playwright/test';
import { faker } from '@faker-js/faker';
import { getEnv } from '../../../utils/utils';
import { apps } from '../../../utils/apps';

test.describe(apps.minio.title, () => {
    for (const instance of apps.minio.instances) {
        const consoleUrl = instance.url.replace(/^(https?:\/\/)/, '$1console.');

        test.describe(instance.title, () => {
            test('UI: Successful login', async ({ page }) => {
                await page.goto(consoleUrl);
                await page.waitForURL(`${consoleUrl}/login`);
                await page.locator('input#accessKey').fill('admin');
                await page.locator('input#secretKey').fill(getEnv(instance.url, 'PASSWORD'));
                await page.locator('button#do-login[type=submit]').click();
                await page.waitForURL(`${consoleUrl}/browser`);
            });

            test('UI: Unsuccessful login', async ({ page }) => {
                await page.goto(consoleUrl);
                await page.waitForURL(`${consoleUrl}/login`);
                const originalUrl = page.url();
                await page.locator('input#accessKey').fill('admin');
                await page.locator('input#secretKey').fill(faker.string.alpha(10));
                await page.locator('button#do-login[type=submit]').click();
                await expect(page.locator('.messageTruncation:has-text("invalid Login.")')).toBeVisible();
                expect(page.url(), 'URL should not change').toStrictEqual(originalUrl);
            });

            test('API: Root', async () => {
                const userAgent = new UserAgent([/Chrome/, { platform: 'Win32', vendor: 'Google Inc.' }]).toString();
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999, headers: { 'User-Agent': userAgent }, validateStatus: () => true});
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Redirect to console', async () => {
                const userAgent = new UserAgent([/Chrome/, { platform: 'Win32', vendor: 'Google Inc.' }]).toString();
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, headers: { 'User-Agent': userAgent }, validateStatus: () => true });
                expect(response.status, 'Response Status').toStrictEqual(307);
                expect(response.headers['location'], 'Response header location').toStrictEqual(consoleUrl);
            });

            test('API: Console root', async () => {
                const response = await axios.get(consoleUrl, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
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
                    const response = await axios.get(`${instance.url}/.apache/status`, {
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
