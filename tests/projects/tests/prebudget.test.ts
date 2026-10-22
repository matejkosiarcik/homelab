import { expect, test } from '#/playwright/test.ts';
import { apps } from '#/utils/apps.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '#/utils/tests.ts';
import { axios } from '#/utils/utils.ts';

const app = apps.prebudget;

test.describe(app.title, () => {
    for (const instance of app.instances) {
        if ('enabled' in instance && instance.enabled === false) {
            test.skip(`Instance ${app.title} ${instance.title} is disabled`, () => {});
            continue;
        }

        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            test('API: Get healthcheck', async () => {
                const response = await test.step('Request server', async () => {
                    const response = await axios.get(`${instance.url}/.health`);
                    expect(response.status, 'Response status').toStrictEqual(200);
                    return response;
                });

                await test.step('Validate response', async () => {
                    expect(response.data, 'Response body').toStrictEqual('OK');
                });
            });

            test('UI: Open login page', async ({ page }) => {
                await test.step('Open application', async () => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/login`);
                });

                await test.step('login', async () => {
                    await expect(page).toHaveTitle('PreBudget | Log in');
                    await expect(page.locator('form.login-form')).toBeVisible();
                    await expect(page.locator('input[name="username"]')).toBeVisible();
                    await expect(page.locator('input[name="password"]')).toBeVisible();
                    await expect(page.locator('button[type="submit"]:has-text("Log in")')).toBeVisible();
                });

                await test.step('Validate login', async () => {
                    // TODO: Finish this step
                });
            });
        });
    }
});
