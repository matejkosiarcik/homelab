import { test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createHttpToHttpsRedirectTests, createProxyTests, createTcpTest } from '../../utils/tests';

test.describe(apps.prometheus.title, () => {
    for (const instance of apps.prometheus.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }
        });
    }
});
