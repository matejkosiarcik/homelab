import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { axios, getEnv } from '../../utils/utils';
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
            createHttpToHttpsRedirectTests(instance.url);
            createHttpToHttpsRedirectTests(`${instance.url.replace('https://', 'http://')}:9981`);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443, 9981, 9982]);
            createFaviconTests(instance.url);

            test('API: Info', async () => {
                const response = await axios.get(`${instance.url}/api/serverinfo`);
                expect(response.status, 'Response Status').toStrictEqual(200);
                const body = response.data as TvheadendServerInfoResponse;
                expect(body.api_version, 'API Version').toBeGreaterThan(0);
                expect(body.sw_version, 'SW Version').toMatch(/.+/);
                expect(body.name, 'Name').toMatch(/.+/);
                expect(body.capabilities, 'Capabilities').not.toHaveLength(0);
            });

            test('UI: Open - No user', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/extjs.html`);
                await expect(page.locator('.x-tab-panel-header .x-tab-extra-comp:has-text("(login)")')).toBeVisible({ timeout: 10_000 });
            });

            const validUsers = [
                {
                    user: 'test',
                },
                {
                    user: 'stream',
                },
            ];
            for (const variant of validUsers) {
                test(`UI: Successful open - User ${variant.user}`, async ({ browser }) => {
                    const page = await browser.newPage({ httpCredentials: { username: variant.user, password: getEnv(instance.url, `${variant.user}_PASSWORD`) } });
                    try {
                        await page.goto(instance.url);
                        await page.waitForURL(`${instance.url}/extjs.html`);
                        await expect(page.locator('.x-tab-panel-header .x-tab-extra-comp:has-text("(login)")')).toBeVisible({ timeout: 10_000 });
                        await page.locator('.x-tab-panel-header .x-tab-extra-comp:has-text("(login)")').click({ timeout: 5000 });
                        await expect(page.locator(`.x-tab-panel-header .x-tab-strip-text:has-text("Logged in as ${variant.user}")`)).toBeVisible({ timeout: 10_000 });
                    } finally {
                        await page.close();
                    }
                });
            }

            const invalidUsers = [
                {
                    title: 'Random user',
                    user: faker.string.alpha(10),
                },
                {
                    title: 'User test',
                    user: 'test',
                },
            ];
            for (const variant of invalidUsers) {
                test(`UI: Unsuccessful open - ${variant.title}`, async ({ browser }) => {
                    const page = await browser.newPage({ httpCredentials: { username: variant.user, password: faker.string.alpha(10) } });
                    try {
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
        });
    }
});
