import https from 'node:https';
import axios from 'axios';
import { expect, test } from '@playwright/test';
import { apps } from '../../../utils/apps';
import { createProxyStatusTests, createTcpTest } from '../../../utils/tests';

test.describe(apps.ntfy.title, () => {
    for (const instance of apps.ntfy.instances) {
        test.describe(instance.title, () => {
            // TODO: Add test for HTTP->HTTPS redirects after real Let's Encrypt certificates
            createProxyStatusTests(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });
        });
    }
});
