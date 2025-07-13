import { test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps.ollama.title, () => {
    for (const instance of apps.ollama.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            // TODO: createPrometheusTests(instance.url, { auth: 'basic' });
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            // TODO: Add tests for API endpoints
        });
    }
});
