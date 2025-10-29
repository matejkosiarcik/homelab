import { test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps.adventurelog.title, () => {
    for (const instance of apps.adventurelog.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createHttpToHttpsRedirectTests(instance.backendUrl, { title: 'console' });
            createProxyTests(instance.url);
            createProxyTests(instance.backendUrl, { title: 'console' });
            createApiRootTest(instance.url);
            createApiRootTest(instance.backendUrl, { title: 'console' });
            createTcpTests(instance.url, [80, 443]);
            createTcpTests(instance.backendUrl, [80, 443], { title: 'console' });
            createFaviconTests(instance.url);
            createFaviconTests(instance.backendUrl, { title: 'console' });

            // TODO: Finish tests
        });
    }
});
