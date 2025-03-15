import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createHttpToHttpsRedirectTests, createProxyTests, createTcpTest } from '../../utils/tests';
import { axios } from '../../utils/utils';

type DockerProxyCatalogResponse = {
    repositories: string[];
};

test.describe(apps['docker-proxy'].title, () => {
    for (const instance of apps['docker-proxy'].instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

            test('API: Catalog', async () => {
                const response = await axios.get(`${instance.url}/v2/_catalog`);
                expect(response.status, 'Response Status').toStrictEqual(200);
                const body = response.data as DockerProxyCatalogResponse;
                expect(body.repositories, 'Response repositories').not.toHaveLength(0);
            });
        });
    }
});
