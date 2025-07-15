import { test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { getEnv } from '../../utils/utils';

test.describe(apps.owntracks.title, () => {
    for (const instance of apps.owntracks.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            // createPrometheusTests(instance.url, { auth: 'basic' });
            createApiRootTest(instance.url, { title: 'Unauthenticated', status: 401 });
            createApiRootTest(instance.url, {
                title: 'Authenticated (admin)',
                headers: {
                    Authorization: `Basic ${Buffer.from(`admin:${getEnv(instance.url, 'ADMIN_PASSWORD')}`).toString('base64')}`
                },
            });
            createApiRootTest(instance.url, {
                title: 'Authenticated (matej)',
                headers: {
                    Authorization: `Basic ${Buffer.from(`matej:${getEnv(instance.url, 'ADMIN_PASSWORD')}`).toString('base64')}`
                },
            });
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            // TODO: Add API tests
            // TODO: Add UI tests
        });
    }
});
