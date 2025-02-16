import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createHttpToHttpsRedirectTests, createProxyStatusTests, createTcpTest } from '../../utils/tests';
import { getEnv } from '../../utils/utils';

type MotioneyeError = {
    error: string,
    prompt: boolean,
};

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
                    test(`UI: Successful full login - User ${variant.username}`, async ({ page }) => {
                        await page.goto(instance.url);
                        await page.waitForURL(`${instance.url}/`);
                        await page.locator('form input[name="username"]').fill(variant.username);
                        await page.locator('form input[name="password"]').fill(getEnv(instance.url, `${variant.username}_PASSWORD`));
                        await page.locator('.button:has-text("Login")').click();
                        await page.waitForURL(`${instance.url}/`);
                        await expect(page.locator('img.camera')).toBeVisible();
                        await expect(page.locator('.settings-top-bar .icon.settings-button')).toBeVisible();
                    });

                    test(`UI: Successful embed open - User ${variant.username}`, async ({ page }) => {
                        await page.goto(`${instance.url}/picture/1/frame/`);
                        await page.waitForURL(`${instance.url}/picture/1/frame/`);
                        await page.locator('form input[name="username"]').fill(variant.username);
                        await page.locator('form input[name="password"]').fill(getEnv(instance.url, `${variant.username}_PASSWORD`));
                        await page.locator('.button:has-text("Login")').click();
                        await page.waitForURL(`${instance.url}/picture/1/frame/`);
                        await expect(page.locator('.admin .icon.settings-button')).not.toBeVisible();
                        await expect(page.locator('img.camera')).toBeVisible();
                    });
                }

                if (variant.username === 'user') {
                    test(`UI: Successful stream open - User ${variant.username}`, async ({ page }) => {
                        await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${variant.username}:${getEnv(instance.url, `${variant.username}_PASSWORD`)}`).toString('base64')}` });
                        await page.goto(`${instance.url}:9081`, { waitUntil: 'commit' });
                        await expect(page.locator('body > img')).toBeVisible({ timeout: 5000 });
                    });
                }

                test(`UI: Unsuccessful full login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/`);
                    await page.locator('form input[name="username"]').fill(variant.username);
                    await page.locator('form input[name="password"]').fill(faker.string.alpha(10));
                    await page.locator('.button:has-text("Login")').click();
                    await page.waitForURL(`${instance.url}/`);
                    await expect(page.locator('.login-dialog-error:has-text("Invalid credentials.")')).toBeVisible();
                });

                test(`UI: Unsuccessful embed open - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.goto(`${instance.url}/picture/1/frame/`);
                    await page.waitForURL(`${instance.url}/picture/1/frame/`);
                    await page.locator('form input[name="username"]').fill(variant.username);
                    await page.locator('form input[name="password"]').fill(faker.string.alpha(10));
                    await page.locator('.button:has-text("Login")').click();
                    await page.waitForURL(`${instance.url}/picture/1/frame/`);
                    await expect(page.locator('.login-dialog-error:has-text("Invalid credentials.")')).toBeVisible();
                });

                test(`API: Unsuccessful stream open - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async () => {
                    const response = await axios.get(`${instance.url}:9081`, {
                        auth: {
                            username: variant.username,
                            password: faker.string.alpha(10),
                        },
                        maxRedirects: 999,
                        validateStatus: () => true,
                        httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                    });
                    expect(response.status, 'Response Status').toStrictEqual(401);
                });
            }

            test(`API: Unsuccessful stream open - No user`, async () => {
                const response = await axios.get(`${instance.url}:9081`, {
                    maxRedirects: 999,
                    validateStatus: () => true,
                    httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                });
                expect(response.status, 'Response Status').toStrictEqual(401);
            });

            test(`API: Unsuccessful snapshot open - No user`, async () => {
                const response = await axios.get(`${instance.url}/picture/1/current`, {
                    maxRedirects: 999,
                    validateStatus: () => true,
                    httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                });
                expect(response.status, 'Response Status').toStrictEqual(403);
                const body = response.data as MotioneyeError;
                expect(body).toStrictEqual({ error: 'unauthorized', prompt: false });
            });
        });
    }
});
