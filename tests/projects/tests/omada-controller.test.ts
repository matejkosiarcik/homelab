import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { axios, getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';

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

test.describe(apps['omada-controller'].title, () => {
    for (const instance of apps['omada-controller'].instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443, 29811, 29812, 29813, 29814, 29815, 29816]);
            createFaviconTests(instance.url);

            test('API: Status endpoint', async () => {
                const response = await axios.get(`${instance.url}/api/v2/anon/info`);
                expect(response.status, 'Response Status').toStrictEqual(200);
                const body = response.data as OmadaControllerStatusResponse;
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

            test('UI: Unsuccessful login - Random user', async ({ page }) => {
                await page.goto(instance.url);
                await page.locator('.login-form input[placeholder^="Username"]').waitFor({ state: 'visible', timeout: 6000 });
                const originalUrl = page.url();
                await page.locator('.login-form input[placeholder^="Username"]').fill(faker.string.alpha(10));
                await page.locator('.login-form input[type="password"]').fill(faker.string.alpha(10));
                await page.locator('.login-form a.button-button[title="Log in"]').click();
                await expect(page.locator('.error-tips-content:has-text("Invalid username or password.")')).toBeVisible();
                await expect(page, 'URL should not change').toHaveURL(originalUrl);
            });

            test('UI: Successful login - User viewer', async ({ page }) => {
                await page.goto(instance.url);
                await page.locator('.login-form input[placeholder^="Username"]').waitFor({ state: 'visible', timeout: 6000 });
                await page.locator('.login-form input[placeholder^="Username"]').fill('viewer');
                await page.locator('.login-form input[type="password"]').fill(getEnv(instance.url, 'VIEWER_PASSWORD'));
                await page.locator('.login-form a.button-button[title="Log in"]').click();
                await page.waitForURL(`${instance.url}/#dashboardGlobal`);
                await expect(page.locator('#main-view .header__menu')).toBeVisible();
                await expect(page.locator('#main-view #app')).toBeVisible();
            });
        });
    }
});
