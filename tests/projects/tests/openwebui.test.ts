import { test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps['openwebui'].title, () => {
    for (const instance of apps['openwebui'].instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            // TODO: createPrometheusTests(instance.url, { auth: 'basic' });
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            // TODO: Add tests for API endpoints
            // TODO: Add tests for UI
        });
    }
});
