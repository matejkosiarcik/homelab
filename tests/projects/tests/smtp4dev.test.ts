import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { getEnv } from '../../utils/utils';
import { faker } from '@faker-js/faker';
import axios from 'axios';

// Smtp4dev
type Smtp4devResponse = {
    results: [
        {
            isRelayed: boolean,
            deliveredTo: string,
            id: string,
            from: string,
            to: string[],
            receivedDate: string,
            subject: string,
            attachmentCount: number,
            isUnread: boolean,
        },
    ],
    currentPage: number,
    pageCount: number,
    pageSize: number,
    rowCount: number,
    firstRowOnPage: number,
    lastRowOnPage: number,
};

test.describe(apps.smtp4dev.title, () => {
    for (const instance of apps.smtp4dev.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url, { title: 'Unauthenticated', status: 401 });
            createApiRootTest(instance.url, {
                title: 'Authenticated',
                headers: {
                    Authorization: `Basic ${Buffer.from(`admin:${getEnv(instance.url, 'ADMIN_PASSWORD')}`).toString('base64')}`
                },
            });
            createTcpTests(instance.url, [25, 80, 443]);
            createFaviconTests(instance.url);

            const users = [
                {
                    username: 'admin',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                }
            ];
            for (const user of users) {
                if (!user.random) {
                    test(`UI: Successful open - User ${user.username}`, async ({ page }) => {
                        await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${user.username}:${getEnv(instance.url, 'ADMIN_PASSWORD')}`).toString('base64')}` });
                        await page.goto(instance.url);
                        await expect(page.locator('#tab-messages')).toBeVisible({ timeout: 5000 });
                    });

                    test(`API: Successful messages - ${user.random ? 'Random user' : `User ${user.username}`}`, async () => {
                        const response = await axios.get(`${instance.url}/api/messages?page=1&pageSize=10`, {
                            auth: {
                                username: user.username,
                                password: getEnv(instance.url, 'ADMIN_PASSWORD'),
                            },
                        });
                        expect(response.status, 'Response Status').toStrictEqual(200);
                    });
                }

                test(`UI: Unsuccessful open - ${user.random ? 'Random user' : `User ${user.username}`}`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${user.username}:${faker.string.alphanumeric(10)}`).toString('base64')}` });
                    try {
                        await page.goto(instance.url);
                    } catch {
                        // Ignore error
                    }
                    await expect(page.locator('#tab-messages')).not.toBeVisible({ timeout: 5000 });
                });

                test(`API: Unsuccessful messages - ${user.random ? 'Random user' : `User ${user.username}`}`, async () => {
                    const response = await axios.get(`${instance.url}/api/messages?page=1&pageSize=10`, {
                        auth: {
                            username: user.username,
                            password: faker.string.alpha(10),
                        },
                        validateStatus: () => true,
                    });
                    expect(response.status, 'Response Status').toStrictEqual(401);
                });
            }

            test('UI: Unsuccessful open - No user', async ({ page }) => {
                try {
                    await page.goto(instance.url);
                } catch {
                    // Ignore error
                }
                await expect(page.locator('#tab-messages')).not.toBeVisible({ timeout: 5000 });
            });

            test('API: Successful get messages', async () => {
                const response = await axios.get(`${instance.url}/api/messages?page=1&pageSize=10`, {
                    auth: {
                        username: 'admin',
                        password: getEnv(instance.url, 'ADMIN_PASSWORD'),
                    },
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
                const data = response.data as Smtp4devResponse;
                expect(typeof data.currentPage, 'Data currentPage should be number').toStrictEqual('number');
                expect(typeof data.firstRowOnPage, 'Data firstRowOnPage should be number').toStrictEqual('number');
                expect(typeof data.lastRowOnPage, 'Data lastRowOnPage should be number').toStrictEqual('number');
                expect(typeof data.pageCount, 'Data pageCount should be number').toStrictEqual('number');
                expect(typeof data.pageSize, 'Data pageSize should be number').toStrictEqual('number');
                expect(typeof data.rowCount, 'Data rowCount should be number').toStrictEqual('number');
                expect(data.results, 'Data results should be array').toBeInstanceOf(Array);
                expect(data.currentPage, 'Data results should be array').toStrictEqual(1);
                expect(data.lastRowOnPage, 'Data results should be array').toBeGreaterThanOrEqual(data.firstRowOnPage - 1);
                expect(data.pageSize, 'Data results should be array').toStrictEqual(10);
            });
        });
    }
});
