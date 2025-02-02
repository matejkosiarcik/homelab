import https from 'node:https';
import axios from 'axios';
import { expect, test } from '@playwright/test';
import { faker } from '@faker-js/faker';
import { getEnv } from '../../../utils/utils';
import { apps } from '../../../utils/apps';

test.describe(apps['unifi-controller'].title, () => {
    for (const instance of apps['unifi-controller'].instances) {
        test.describe(instance.title, () => {
            test('UI: Successful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(/\/manage\/account\/login(?:\?.*)?$/);
                await page.locator('form input[name="username"]').waitFor({ state: 'visible', timeout: 6000 });
                await page.locator('form input[name="username"]').fill('admin');
                await page.locator('form input[name="password"]').fill(getEnv(instance.url, 'PASSWORD'));
                await page.locator('button#loginButton').click();
                await page.waitForURL(`${instance.url}/manage/default/dashboard`);
            });

            test('UI: Unsuccessful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(/\/manage\/account\/login(?:\?.*)?$/);
                await page.locator('form input[name="username"]').waitFor({ state: 'visible', timeout: 6000 });
                const originalUrl = page.url();
                await page.locator('form input[name="username"]').fill('admin');
                await page.locator('form input[name="password"]').fill(faker.string.alpha(10));
                await page.locator('button#loginButton').click();
                await expect(page.locator('.appInfoBox--danger:has-text("Invalid username and/or password.")')).toBeVisible();
                expect(page.url(), 'URL should not change').toStrictEqual(originalUrl);
            });

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Status endpoint', async () => {
                const response = await axios.get(`${instance.url}/status`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
                const body = response.data as UnifiControllerStatusResponse;
                type UnifiControllerStatusResponse = {
                    meta: {
                        rc: string,
                        server_version: string,
                        up: boolean,
                        uuid: string,
                    },
                    data: unknown[],
                };
                expect(body.meta.rc, 'Response body .meta.rc').toStrictEqual('ok');
                expect(body.meta.up, 'Response body .meta.up').toStrictEqual(true);
                expect(body.meta.uuid, 'Response body .meta.uuid').toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/);
                expect(body.meta.server_version, 'Response body .meta.server_version').toMatch(/^\d+\.\d+\.\d+$/);
                expect(body.data, 'Response body .data').toHaveLength(0);
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
        });
    }
});
