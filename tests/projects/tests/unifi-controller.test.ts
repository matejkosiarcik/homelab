import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { axios, getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createApiRootTest, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';

type UnifiControllerStatusResponse = {
    meta: {
        rc: string,
        server_version: string,
        up: boolean,
        uuid: string,
    },
    data: unknown[],
};

test.describe(apps['unifi-controller'].title, () => {
    for (const instance of apps['unifi-controller'].instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443, 8080, 8443]); // port 6789 skipped

            test('API: Status endpoint', async () => {
                const response = await axios.get(`${instance.url}/status`);
                expect(response.status, 'Response Status').toStrictEqual(200);
                const body = response.data as UnifiControllerStatusResponse;
                expect(body.meta.rc, 'Response body .meta.rc').toStrictEqual('ok');
                expect(body.meta.up, 'Response body .meta.up').toStrictEqual(true);
                expect(body.meta.uuid, 'Response body .meta.uuid').toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/);
                expect(body.meta.server_version, 'Response body .meta.server_version').toMatch(/^\d+\.\d+\.\d+$/);
                expect(body.data, 'Response body .data').toHaveLength(0);
            });

            const users = [
                {
                    username: 'admin',
                },
                {
                    username: 'viewer',
                },
                {
                    username: 'homepage',
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
                        await page.waitForURL(/\/manage\/account\/login(?:\?.*)?$/);
                        await page.locator('form input[name="username"]').waitFor({ state: 'visible', timeout: 6000 });
                        await page.locator('form input[name="username"]').fill(variant.username);
                        await page.locator('form input[name="password"]').fill(getEnv(instance.url, `${variant.username}_PASSWORD`));
                        await page.locator('button#loginButton').click();
                        await page.waitForURL(`${instance.url}/manage/default/dashboard`, { timeout: 30_000 });
                        await expect(page.locator('#unifi-network-app-container [data-testid="activity-insights-graph"]')).toBeVisible({ timeout: 20_000 });
                    });
                }

                test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(/\/manage\/account\/login(?:\?.*)?$/);
                    await page.locator('form input[name="username"]').waitFor({ state: 'visible', timeout: 6000 });
                    const originalUrl = page.url();
                    await page.locator('form input[name="username"]').fill(variant.username);
                    await page.locator('form input[name="password"]').fill(faker.string.alpha(10));
                    await page.locator('button#loginButton').click();
                    await expect(page.locator('.appInfoBox--danger:has-text("Invalid username and/or password.")')).toBeVisible();
                    await expect(page, 'URL should not change').toHaveURL(originalUrl);
                });
            }
        });
    }
});
