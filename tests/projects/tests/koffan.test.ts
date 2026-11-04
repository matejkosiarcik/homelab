import { expect, test } from '#/playwright/test.ts';
import { apps } from '#/utils/apps.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '#/utils/tests.ts';
import { axios } from '#/utils/axios.ts';

const app = apps.koffan;

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

            test('API: Login subpage', async () => {
                await test.step('Request server', async () => {
                    const response = await axios.get(`${instance.url}/login`);
                    expect(response.status, 'Response Status').toStrictEqual(200);
                    expect(response.headers['content-type'], 'Response content type').toMatch(/^text\/html(?:;\s*charset=.*)?$/i);
                });
            });

            test.skip('PLACEHOLDER', () => {
                // TODO: Finish tests
            });
        });
    }
});
