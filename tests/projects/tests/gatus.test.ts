import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { getEnv } from '../../utils/utils';
import { createHttpToHttpsRedirectTests, createProxyStatusTests, createTcpTest } from '../../utils/tests';

test.describe(apps.gatus.title, () => {
    for (const instance of apps.gatus.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyStatusTests(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

            test('API: Root', async () => {
                const response = await axios.get(instance.url, {
                    httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                    maxRedirects: 999,
                    validateStatus: () => true
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            const prometheusVariants = [
                {
                    title: 'missing credentials',
                    auth: undefined as unknown as { username: string, password: string },
                    status: 401,
                },
                {
                    title: 'wrong credentials',
                    auth: {
                        username: 'prometheus',
                        password: faker.string.alphanumeric(10),
                    },
                    status: 401,
                },
                {
                    title: 'successful',
                    auth: {
                        username: 'prometheus',
                        password: getEnv(instance.url, 'PROMETHEUS_PASSWORD'),
                    },
                    status: 200,
                },
            ];
            for (const variant of prometheusVariants) {
                test(`API: Prometheus metrics (${variant.title})`, async () => {
                    const response = await axios.get(`${instance.url}/metrics`, {
                        auth: variant.auth,
                        maxRedirects: 999,
                        validateStatus: () => true,
                        httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                    });
                    expect(response.status, 'Response Status').toStrictEqual(variant.status);
                });
            }

            test('UI: Open', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('#results .endpoint-group').first()).toBeVisible({ timeout: 10_000 });
            });
        });
    }
});
