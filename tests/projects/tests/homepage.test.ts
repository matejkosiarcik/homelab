import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { axios, getEnv } from '../../utils/utils';

test.describe(apps.homepage.title, () => {
    for (const instance of apps.homepage.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url, { title: 'Unauthenticated', status: 401 });
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            const validUsers = [
                {
                    username: 'matej'
                },
                {
                    username: 'homelab-viewer',
                },
                {
                    username: 'homelab-test',
                },
            ];
            for (const user of validUsers) {
                createApiRootTest(instance.url, {
                    title: `Authenticated - User ${user.username}`,
                    headers: {
                        Authorization: `Basic ${Buffer.from(`${user.username}:${getEnv(instance.url, `${user.username}_PASSWORD`)}`).toString('base64')}`
                    },
                });

                test(`UI: Successful open - User ${user.username}`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${user.username}:${getEnv(instance.url, `${user.username.toUpperCase()}_PASSWORD`)}`).toString('base64')}` });
                    await page.goto(instance.url);
                    await expect(page.locator('ul.services-list li.service').first()).toBeVisible();
                });

                test(`API: Successful root - User ${user.username}`, async () => {
                    const response = await axios.get(instance.url, {
                        headers: {
                            Authorization: `Basic ${Buffer.from(`${user.username}:${getEnv(instance.url, `${user.username.toUpperCase()}_PASSWORD`)}`).toString('base64')}`,
                        },
                    });
                    expect(response.status, 'Response Status').toStrictEqual(200);
                });
            }

            const invalidUsers = [
                {
                    username: 'homelab-test',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful open - ${user.random ? 'Random user' : `User ${user.username}`}`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${user.username}:${faker.string.alphanumeric(10)}`).toString('base64')}` });
                    await page.goto(instance.url);
                    await expect(page.locator('ul.services-list li.service').first()).not.toBeVisible();
                });

                test(`API: Unsuccessful get root without password - ${user.random ? 'Random user' : `User ${user.username}`}`, async () => {
                    const response = await axios.get(instance.url, {
                        headers: {
                            Authorization: `Basic ${Buffer.from(`${user.username}:`).toString('base64')}`,
                        },
                    });
                    expect(response.status, 'Response Status').toStrictEqual(401);
                });

                test(`API: Unsuccessful get root with bad password - ${user.random ? 'Random user' : `User ${user.username}`}`, async () => {
                    const response = await axios.get(instance.url, {
                        headers: {
                            Authorization: `Basic ${Buffer.from(`${user.username}:${faker.string.alphanumeric(10)}`).toString('base64')}`,
                        },
                    });
                    expect(response.status, 'Response Status').toStrictEqual(401);
                });
            }

            test('UI: Unsuccessful open - No user', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('ul.services-list li.service').first()).not.toBeVisible();
            });


            test('API: Get healthcheck', async () => {
                const response = await axios.get(`${instance.url}/api/healthcheck`, {
                    headers: {
                        Authorization: `Basic ${Buffer.from(`homelab-viewer:${getEnv(instance.url, 'HOMELAB_VIEWER_PASSWORD')}`).toString('base64')}`,
                    },
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
                expect(response.data, 'Response Content').toStrictEqual('up');
            });
        });
    }
});
