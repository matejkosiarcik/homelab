import https from 'node:https';
import axios from 'axios';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createHttpToHttpsRedirectTests, createProxyStatusTests, createTcpTest } from '../../utils/tests';
import { getEnv } from '../../utils/utils';
import { faker } from '@faker-js/faker';

type TvheadendServerInfoResponse = {
    sw_version: string,
    api_version: number,
    name: string,
    capabilities: string[],
};

test.describe(apps.tvheadend.title, () => {
    for (const instance of apps.tvheadend.instances) {
        test.describe(instance.title, () => {
            const httpUrl9981 = `${instance.url.replace('https://', 'http://')}:9981`; // TODO: Remove after real Let's encrypt certificates

            createHttpToHttpsRedirectTests(instance.url);
            createProxyStatusTests(instance.url);

            for (const port of [80, 443, 9981, 9982]) {
                createTcpTest(instance.url, port);
            }

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

            const users = [
                {
                    username: 'admin',
                },
                {
                    username: 'user',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                }
            ];
            for (const variant of users) {
                if (!variant.random) {
                    test(`UI: Successful open - User ${variant.username}`, async ({ browser }) => {
                        const page = await browser.newPage({ httpCredentials: { username: variant.username, password: getEnv(instance.url, `${variant.username}_PASSWORD`) } });
                        try {
                            await page.goto(instance.url);
                            await page.waitForURL(`${instance.url}/extjs.html`);
                            await expect(page.locator('.x-tab-panel-header .x-tab-extra-comp:has-text("(login)")')).toBeVisible({ timeout: 10_000 });
                            await page.locator('.x-tab-panel-header .x-tab-extra-comp:has-text("(login)")').click({ timeout: 5000 });
                            await expect(page.locator(`.x-tab-panel-header .x-tab-strip-text:has-text("Logged in as ${variant.username}")`)).toBeVisible({ timeout: 10_000 });
                        } finally {
                            await page.close();
                        }
                    });
                }

                test(`UI: Unsuccessful open - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ browser }) => {
                    const page = await browser.newPage({ httpCredentials: { username: variant.username, password: faker.string.alpha(10) } });
                    try {
                        // await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${variant.username}:${faker.string.alphanumeric(10)}`).toString('base64')}` });
                        await page.goto(instance.url);
                        await page.waitForURL(`${instance.url}/extjs.html`);
                        await expect(page.locator('.x-tab-panel-header .x-tab-extra-comp:has-text("(login)")')).toBeVisible({ timeout: 10_000 });
                        await page.locator('.x-tab-panel-header .x-tab-extra-comp:has-text("(login)")').click({ timeout: 5000 });
                        await expect(page.locator('body h1:has-text("403 Forbidden")')).toBeVisible();
                    } finally {
                        await page.close();
                    }
                });
            }

            test('UI: Open - No user', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/extjs.html`);
                await expect(page.locator('.x-tab-panel-header .x-tab-extra-comp:has-text("(login)")')).toBeVisible({ timeout: 10_000 });
            });

            test('UI: Open :9981', async ({ page }) => { // TODO: Remove after real Let's encrypt certificates
                await page.goto(httpUrl9981);
                await page.waitForURL(`${httpUrl9981}/extjs.html`);
                await expect(page.locator('.x-tab-panel-header .x-tab-extra-comp:has-text("(login)")')).toBeVisible({ timeout: 10_000 });
            });
        });
    }
});
