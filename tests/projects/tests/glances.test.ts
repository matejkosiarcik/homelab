import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createHttpToHttpsRedirectTests, createProxyTests, createTcpTest } from '../../utils/tests';
import { getEnv } from '../../utils/utils';

test.describe(apps.glances.title, () => {
    for (const instance of apps.glances.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

            const users = [
                {
                    username: 'glances',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                }
            ];
            for (const variant of users) {
                if (!variant.random) {
                    test('API: Successful get root', async () => {
                        const response = await axios.get(instance.url, {
                            auth: {
                                username: variant.username,
                                password: getEnv(instance.url, 'PASSWORD'),
                            },
                            httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                            maxRedirects: 999,
                            validateStatus: () => true
                        });
                        expect(response.status, 'Response Status').toStrictEqual(200);
                    });

                    test(`UI: Successful open - User ${variant.username}`, async ({ page }) => {
                        await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${variant.username}:${getEnv(instance.url, 'PASSWORD')}`).toString('base64')}` });
                        await page.goto(instance.url);
                        await expect(page.locator('#app #cpu.plugin')).toBeVisible();
                    });
                }

                test(`API: Unsuccessful get root - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async () => {
                    const response = await axios.get(instance.url, {
                        auth: {
                            username: variant.username,
                            password: faker.string.alphanumeric(10),
                        },
                        httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                        maxRedirects: 999,
                        validateStatus: () => true
                    });
                    expect(response.status, 'Response Status').toStrictEqual(401);
                });

                test(`UI: Unsuccessful open - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${variant.username}:${faker.string.alphanumeric(10)}`).toString('base64')}` });
                    await page.goto(instance.url);
                    await expect(page.locator('#app #cpu.plugin')).not.toBeVisible();
                });
            }

            test('API: Unsuccessful get root - No user', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999, validateStatus: () => true });
                expect(response.status, 'Response Status').toStrictEqual(401);
            });

            test('UI: Unsuccessful open - No user', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('#app #cpu.plugin')).not.toBeVisible();
            });
        });
    }
});
