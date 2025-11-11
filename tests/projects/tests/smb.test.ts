import _ from 'lodash';
import { test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps.samba.title, () => {
    for (const instance of apps.samba.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url.replace(/^smb:\/\//, 'https://'));
            createProxyTests(instance.url.replace(/^smb:\/\//, 'https://'));
            createApiRootTest(instance.url.replace(/^smb:\/\//, 'https://'));
            createTcpTests(instance.url.replace(/^smb:\/\//, 'https://'), [80, 139, 443, 445]);
            createFaviconTests(instance.url.replace(/^smb:\/\//, 'https://'));
        });
    }
});
