import { test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps.npmcache.title, () => {
    for (const instance of apps.npmcache.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'basic' });
            createApiRootTest(instance.url, { title: 'Unauthenticated', status: 401 });
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            // TODO: Finish
        });
    }
});
