import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests.ts';
import { axios, getEnv } from '../../utils/utils.ts';

const app = apps.homepage;

test.describe(app.title, () => {
    for (const instance of app.instances) {
        if ('enabled' in instance && instance.enabled === false) {
            test.skip(`Instance ${app.title} ${instance.title} is disabled`, () => {});
            continue;
        }

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
            ];
            for (const user of validUsers) {
                test(`UI: Successful login - User ${user.username}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/auth/signin?callbackUrl=${encodeURIComponent('/')}`);
                    await page.locator('input[name="password"]').fill(getEnv(instance.url, `${user.username}_PASSWORD`));
                    await page.locator('button[type="submit"]').click();
                    await page.waitForURL(`${instance.url}`);
                    await expect(page.locator('ul.services-list li.service').first()).toBeVisible();
                });
            }

            const invalidUsers = [
                {
                    username: 'admin',
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful login with wrong password - User ${user.username}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/auth/signin?callbackUrl=${encodeURIComponent('/')}`);
                    await page.locator('input[name="password"]').fill(faker.string.alphanumeric(10));
                    await page.locator('button[type="submit"]').click();
                    await expect(page.locator('text="Invalid password. Please try again."')).toBeVisible();
                    await page.waitForURL(`${instance.url}/auth/signin?callbackUrl=${encodeURIComponent(instance.url + '/')}&error=CredentialsSignin`);
                    expect(page.url(), 'URL should contain error code').toContain('error=CredentialsSignin');
                });
            }

            test('API: Get healthcheck', async () => {
                const response = await axios.get(`${instance.url}/api/healthcheck`);
                expect(response.status, 'Response Status').toStrictEqual(200);
                expect(response.data, 'Response Content').toStrictEqual('up');
            });
        });
    }
});
