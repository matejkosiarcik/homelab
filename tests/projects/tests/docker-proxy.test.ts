import https from 'node:https';
import axios from 'axios';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createHttpToHttpsRedirectTests, createProxyTests, createTcpTest } from '../../utils/tests';

type DockerProxyCatalogResponse = {
    repositories: string[];
};

test.describe(apps['docker-proxy'].title, () => {
    for (const instance of apps['docker-proxy'].instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Catalog', async () => {
                const response = await axios.get(`${instance.url}/v2/_catalog`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
                const body = response.data as DockerProxyCatalogResponse;
                expect(body.repositories, 'Response repositories').not.toHaveLength(0);
            });
        });
    }
});
