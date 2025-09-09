import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
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
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            test('API: Proper root', async () => {
                const response = await axios.get(`${instance.url}/v2`);
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('API: Catalog', async () => {
                const response = await axios.get(`${instance.url}/v2/_catalog`);
                expect(response.status, 'Response Status').toStrictEqual(200);
                const body = response.data as DockerProxyCatalogResponse;
                expect(body.repositories, 'Response repositories').not.toHaveLength(0);
            });

            test('UI: Open proper root', async ({ page }) => {
                await page.goto(`${instance.url}/v2`);
            });

            test('UI: Open catalog', async ({ page }) => {
                await page.goto(`${instance.url}/v2/_catalog`);
            });
        });
    }
});
