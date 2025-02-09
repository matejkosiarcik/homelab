import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { getEnv } from '../../../utils/utils';
import { apps } from '../../../utils/apps';
import { createTcpTest } from '../../../utils/tests';

test.describe(apps['omada-controller'].title, () => {
    for (const instance of apps['omada-controller'].instances) {
        test.describe(instance.title, () => {
            for (const port of [80, 443, 29811, 29812, 29813, 29814, 29815, 29816]) {
                createTcpTest(instance.url, port);
            }

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
                        await page.goto(instance.url);
                        await page.locator('.login-form input[placeholder^="Username"]').waitFor({ state: 'visible', timeout: 6000 });
                        await page.locator('.login-form input[placeholder^="Username"]').fill(variant.username);
                        await page.locator('.login-form input[type="password"]').fill(getEnv(instance.url, `${variant.username.toUpperCase()}_PASSWORD`));
                        await page.locator('.login-form a.button-button[title="Log in"]').click();
                        await page.waitForURL(`${instance.url}/#dashboardGlobal`);
                    });
                }

                test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.locator('.login-form input[placeholder^="Username"]').waitFor({ state: 'visible', timeout: 6000 });
                    const originalUrl = page.url();
                    await page.locator('.login-form input[placeholder^="Username"]').fill(variant.username);
                    await page.locator('.login-form input[type="password"]').fill(faker.string.alpha(10));
                    await page.locator('.login-form a.button-button[title="Log in"]').click();
                    await expect(page.locator('.error-tips-content:has-text("Invalid username or password.")')).toBeVisible();
                    expect(page.url(), 'URL should not change').toStrictEqual(originalUrl);
                });
            }

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Status endpoint', async () => {
                const response = await axios.get(`${instance.url}/api/v2/anon/info`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
                const body = response.data as OmadaControllerStatusResponse;
                type OmadaControllerStatusResponse = {
                    errorCode: number,
                    msg: string,
                    result: {
                        controllerVer: string,
                        controllerBasicVersion: string,
                        apiVer: string,
                        configured: boolean,
                        type: number,
                        supportApp: boolean,
                        omadacId: string,
                        registeredRoot: boolean,
                        omadacCategory: string,
                        mspMode: boolean,
                    },
                };
                expect(body.errorCode, 'Response body .errorCode').toStrictEqual(0);
                expect(body.msg, 'Response body .msg').toStrictEqual('Success.');
                expect(body.result.controllerBasicVersion, 'Response body .result.controllerBasicVersion').toMatch(/\d+\.\d+\.\d+\.\d+/);
                expect(body.result.controllerVer, 'Response body .result.controllerVer').toMatch(/\d+\.\d+\.\d+\.\d+/);
                expect(body.result.apiVer, 'Response body .result.apiVer').toStrictEqual('3');
                expect(body.result.configured, 'Response body .result.configured').toStrictEqual(true);
                expect(body.result.type, 'Response body .result.type').toStrictEqual(1);
                expect(body.result.supportApp, 'Response body .result.supportApp').toStrictEqual(true);
                expect(body.result.omadacId, 'Response body .result.omadacId').toMatch(/[0-9a-f]+/);
                expect(body.result.registeredRoot, 'Response body .result.registeredRoot').toStrictEqual(true);
                expect(body.result.omadacCategory, 'Response body .result.omadacCategory').toMatch('advanced');
                expect(body.result.mspMode, 'Response body .result.mspMode').toStrictEqual(false);
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
