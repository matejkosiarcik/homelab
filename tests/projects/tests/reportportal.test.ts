import { expect, test } from '#/playwright/test.ts';
import { apps } from '#/utils/apps.ts';
import { axios } from '#/utils/axios.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '#/utils/tests.ts';
import { getEnv } from '#/utils/utils.ts';

const app = apps.reportportal;

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

            for (const service of ['api', 'jobs']) {
                test(`API: ${service} health`, async () => {
                    const response = await axios.get(`${instance.url}/${service}/health`);
                    expect(response.status).toStrictEqual(200);
                });
            }

            const validUsers = [
                {
                    email: 'admin@reportportal.internal',
                    passwordEnv: 'ADMIN_PASSWORD',
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful login - User ${user.email}`, async ({ page }) => {
                    await test.step('Open login', async () => {
                        await page.goto(instance.url);
                    });

                    const response = await test.step('Login', async () => {
                        await page.locator('input[name="login"]').fill(user.email);
                        await page.locator('input[name="password"]').fill(getEnv(instance.url, user.passwordEnv));
                        const response = page.waitForResponse((response) => response.url().includes('/api/sso/oauth/token') && response.request().method() === 'POST');
                        await page.locator('form button[type="submit"]').click();
                        return await response;
                    });

                    await test.step('Validate successful login', async () => {
                        expect(response.status()).toStrictEqual(200);
                        await expect(page.locator('input[name="password"]')).toBeHidden();
                    });
                });
            }

            const invalidUsers = [
                {
                    email: 'nonexistent@reportportal.invalid',
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful login - User ${user.email}`, async ({ page }) => {
                    await test.step('Open login', async () => {
                        await page.goto(instance.url);
                    });

                    await test.step('Attempt login', async () => {
                        await page.locator('input[name="login"]').fill(user.email);
                        await page.locator('input[name="password"]').fill('incorrect-password');
                        await page.locator('form button[type="submit"]').click();
                    });

                    await test.step('Validate unsuccessful login', async () => {
                        await expect(page.getByText('Email or password is incorrect').first()).toBeVisible();
                        await expect(page.locator('input[name="password"]')).toBeVisible();
                    });
                });
            }
        });
    }
});
