import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { axios, getEnv } from '../../utils/utils';
import { faker } from '@faker-js/faker';

test.describe(apps.kiwix.title, () => {
    for (const instance of apps.kiwix.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url, { title: 'Unauthenticated', status: 401 });
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            const validUsers = [
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
                    await page.waitForURL(`${instance.url}/#lang=eng`);
                    await expect(page.locator('.book__list .book').first()).toBeVisible();
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
                    await expect(page.locator('.book__list .book').first()).not.toBeVisible();
                });

                test(`API: Unsuccessful root - ${user.random ? 'Random user' : `User ${user.username}`}`, async () => {
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
                await expect(page.locator('.book__list .book').first()).not.toBeVisible();
            });
        });
    }
});
