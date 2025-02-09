import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { getEnv } from '../../../utils/utils';
import { apps } from '../../../utils/apps';
import { createHttpToHttpsRedirectTests, createTcpTest } from '../../../utils/tests';

type TvheadendServerInfoResponse = {
    sw_version: string,
    api_version: number,
    name: string,
    capabilities: string[],
};

test.describe(apps.tvheadend.title, () => {
    for (const instance of apps.tvheadend.instances) {
        test.describe(instance.title, () => {
            for (const port of [80, 443, 9981, 9982]) {
                createTcpTest(instance.url, port);
            }

            createHttpToHttpsRedirectTests(instance.url);

            const httpUrl9981 = `${instance.url.replace('https://', 'http://')}:9981`;

            test('UI: Open', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/extjs.html`);
                await page.locator('.x-tab-panel-header .x-tab-extra-comp:has-text("(login)")').waitFor({ state: 'visible', timeout: 5000 });
            });

            test('UI: Open :9981', async ({ page }) => { // TODO: Remove after real Let's encrypt certificates
                await page.goto(httpUrl9981);
                await page.waitForURL(`${httpUrl9981}/extjs.html`);
                await page.locator('.x-tab-panel-header .x-tab-extra-comp:has-text("(login)")').waitFor({ state: 'visible', timeout: 5000 });
            });

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Root :9981', async () => {  // TODO: Remove after real Let's encrypt certificates
                const response = await axios.get(httpUrl9981, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Info', async () => {
                const response = await axios.get(`${instance.url}/api/serverinfo`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
                const body = response.data as TvheadendServerInfoResponse;
                expect(body.api_version, 'API Version').toBeGreaterThan(0);
                expect(body.sw_version, 'SW Version').toMatch(/.+/);
                expect(body.name, 'Name').toMatch(/.+/);
                expect(body.capabilities, 'Capabilities').not.toHaveLength(0);
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
