import { expect, test } from '#/playwright/test.ts';
import { apps } from '#/utils/apps.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '#/utils/tests.ts';
import { axios } from '#/utils/axios.ts';

const app = apps.crossroad;

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

            test('UI: Open', async ({ page }) => {
                await test.step('Open application', async () => {
                    await page.goto(instance.url);
                });

                await test.step('Validate application opened successfully', async () => {
                    await expect(page.locator('ul.services-list li.service').first()).toBeVisible();
                });
            });

            test('API: Get healthcheck', async () => {
                const response = await test.step('Request server', async () => {
                    const response = await axios.get(`${instance.url}/api/healthcheck`);
                    expect(response.status, 'Response Status').toStrictEqual(200);
                    return response;
                });

                await test.step('Validate response', async () => {
                    expect(response.data, 'Response Content').toStrictEqual('up');
                });
            });
        });
    }
});
