import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { axios, getEnv } from '../../utils/utils';

type MotioneyeError = {
    error: string,
    prompt: boolean,
};

test.describe(apps.motioneye.title, () => {
    for (const instance of apps.motioneye.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            const validUsers = [
                {
                    username: 'admin',
                },
                {
                    username: 'homelab-stream',
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful full login - User ${user.username}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/`);
                    await page.locator('form input[name="username"]').fill(user.username);
                    await page.locator('form input[name="password"]').fill(getEnv(instance.url, `${user.username}_PASSWORD`));
                    await page.locator('.button:has-text("Login")').click();
                    await page.waitForURL(`${instance.url}/`);
                    await expect(page.locator('img.camera')).toBeVisible();
                    await expect(page.locator('.settings-top-bar .icon.settings-button')).toBeVisible();
                });

                test(`UI: Successful embed open - User ${user.username}`, async ({ page }) => {
                    await page.goto(`${instance.url}/picture/1/frame/`);
                    await page.waitForURL(`${instance.url}/picture/1/frame/`);
                    await page.locator('form input[name="username"]').fill(user.username);
                    await page.locator('form input[name="password"]').fill(getEnv(instance.url, `${user.username}_PASSWORD`));
                    await page.locator('.button:has-text("Login")').click();
                    await page.waitForURL(`${instance.url}/picture/1/frame/`);
                    await expect(page.locator('.admin .icon.settings-button')).not.toBeVisible();
                    await expect(page.locator('img.camera')).toBeVisible();
                });

                if (user.username === 'stream') {
                    test(`UI: Successful stream open - User ${user.username}`, async ({ page }) => {
                        await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${user.username}:${getEnv(instance.url, `${user.username}_PASSWORD`)}`).toString('base64')}` });
                        await page.goto(`${instance.url}/stream`, { waitUntil: 'commit' });
                        await expect(page.locator('body > img')).toBeVisible({ timeout: 5000 });
                    });
                }
            }

            const invalidUsers = [
                {
                    username: faker.string.alpha(10),
                    random: true,
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful full login - ${user.random ? 'Random user' : `User ${user.username}`}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/`);
                    await page.locator('form input[name="username"]').fill(user.username);
                    await page.locator('form input[name="password"]').fill(faker.string.alpha(10));
                    await page.locator('.button:has-text("Login")').click();
                    await page.waitForURL(`${instance.url}/`);
                    await expect(page.locator('.login-dialog-error:has-text("Invalid credentials.")')).toBeVisible();
                });

                test(`UI: Unsuccessful embed open - ${user.random ? 'Random user' : `User ${user.username}`}`, async ({ page }) => {
                    await page.goto(`${instance.url}/picture/1/frame/`);
                    await page.waitForURL(`${instance.url}/picture/1/frame/`);
                    await page.locator('form input[name="username"]').fill(user.username);
                    await page.locator('form input[name="password"]').fill(faker.string.alpha(10));
                    await page.locator('.button:has-text("Login")').click();
                    await page.waitForURL(`${instance.url}/picture/1/frame/`);
                    await expect(page.locator('.login-dialog-error:has-text("Invalid credentials.")')).toBeVisible();
                });

                test(`API: Unsuccessful stream open - ${user.random ? 'Random user' : `User ${user.username}`}`, async () => {
                    const response = await axios.get(`${instance.url}/stream`, {
                        auth: {
                            username: user.username,
                            password: faker.string.alpha(10),
                        },
                    });
                    expect(response.status, 'Response Status').toStrictEqual(401);
                });
            }

            test(`API: Unsuccessful stream open - No user`, async () => {
                const response = await axios.get(`${instance.url}/stream`);
                expect(response.status, 'Response Status').toStrictEqual(401);
            });

            test(`API: Unsuccessful snapshot open - No user`, async () => {
                const response = await axios.get(`${instance.url}/picture/1/current`);
                expect(response.status, 'Response Status').toStrictEqual(403);
                const body = response.data as MotioneyeError;
                expect(body).toStrictEqual({ error: 'unauthorized', prompt: false });
            });
        });
    }
});
