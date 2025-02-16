import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createHttpToHttpsRedirectTests, createProxyStatusTests, createTcpTest } from '../../utils/tests';
import { getEnv } from '../../utils/utils';

test.describe(apps.motioneye.title, () => {
    for (const instance of apps.motioneye.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyStatusTests(instance.url);

            for (const port of [80, 443, 9081]) {
                createTcpTest(instance.url, port);
            }

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            const users = [
                {
                    username: 'admin',
                },
                {
                    username: 'user',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                }
            ];
            for (const variant of users) {
                if (!variant.random) {
                    test(`UI: Successful login - User ${variant.username}`, async ({ page }) => {
                        await page.goto(instance.url);
                        await page.waitForURL(`${instance.url}/`);
                        await page.locator('form input[name="username"]').fill(variant.username);
                        await page.locator('form input[name="password"]').fill(getEnv(instance.url, `${variant.username}_PASSWORD`));
                        await page.locator('.button:has-text("Login")').click();
                        await page.waitForURL(`${instance.url}/`);
                        await expect(page.locator('.page .camera-frame .camera')).toBeVisible();
                    });
                }

                if (variant.username === 'user') {
                    test(`UI: Successful image open - User ${variant.username}`, async ({ page }) => {
                        await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${variant.username}:${getEnv(instance.url, `${variant.username}_PASSWORD`)}`).toString('base64')}` });
                        await page.goto(`${instance.url}:9081`, { waitUntil: 'commit' });
                        await expect(page.locator('body > img')).toBeVisible({ timeout: 5000 });
                    });
                }

                test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/`);
                    await page.locator('form input[name="username"]').fill(variant.username);
                    await page.locator('form input[name="password"]').fill(faker.string.alpha(10));
                    await page.locator('.button:has-text("Login")').click();
                    await page.waitForURL(`${instance.url}/`);
                    await expect(page.locator('.page .camera-frame .camera')).not.toBeVisible();
                    await expect(page.locator('.login-dialog-error:has-text("Invalid credentials.")')).toBeVisible();
                });

                test(`API: Unsuccessful stream open - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async () => {
                    const response = await axios.get(`${instance.url}:9081`, {
                        auth: {
                            username: variant.username,
                            password: faker.string.alpha(10),
                        },
                        timeout: 5000,
                        maxRedirects: 999,
                        validateStatus: () => true,
                        httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                    });
                    expect(response.status, 'Response Status').toStrictEqual(401);
                });
            }

            test(`API: Unsuccessful stream open - No user`, async () => {
                const response = await axios.get(`${instance.url}:9081`, {
                    timeout: 5000,
                    maxRedirects: 999,
                    validateStatus: () => true,
                    httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                });
                expect(response.status, 'Response Status').toStrictEqual(401);
            });
        });
    }
});
