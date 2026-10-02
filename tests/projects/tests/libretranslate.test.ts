import { test } from '@playwright/test';
import { apps } from '../../utils/apps.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests.ts';

const app = apps.libretranslate;

test.describe(app.title, () => {
    for (const instance of app.instances) {
        if ('enabled' in instance && instance.enabled === false) {
            test.skip(`Instance ${app.title} ${instance.title} is disabled`, () => {});
            continue;
        }

        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url, { status: 401 });
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            test.skip('PLACEHOLDER', () => {
                // TODO: Finish tests
            });
        });
    }
});
