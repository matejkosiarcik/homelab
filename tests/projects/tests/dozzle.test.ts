import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createHttpToHttpsRedirectTests, createProxyStatusTests, createTcpTest } from '../../utils/tests';
import { getEnv } from '../../utils/utils';

test.describe(apps.dozzle.title, () => {
    for (const instance of apps.dozzle.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyStatusTests(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

            const users = [
                {
                    username: 'admin',
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
                        await page.waitForURL(`${instance.url}/login?redirectUrl=/`);
                        await page.locator('form input[name="username"]').fill(variant.username);
                        await page.locator('form input[name="password"]').fill(getEnv(instance.url, 'ADMIN_PASSWORD'));
                        await page.locator('form button[type="submit"]:has-text("Login")').click();
                        await page.waitForURL(instance.url);
                        await expect(page.locator('a[href^="/container/"]').first()).toBeVisible();
                    });
                }

                test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/login?redirectUrl=/`);
                    await page.locator('form input[name="username"]').fill(variant.username);
                    await page.locator('form input[name="password"]').fill(faker.string.alpha(10));
                    await page.locator('form button[type="submit"]:has-text("Login")').click();
                    await page.waitForSelector('.text-error:has-text("Username or password are not valid")', { timeout: 10_000 });
                    expect(page.url()).toStrictEqual(`${instance.url}/login?redirectUrl=/`);
                });
            }

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });
        });
    }
});
