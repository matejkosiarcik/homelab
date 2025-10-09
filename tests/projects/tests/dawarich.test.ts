import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { getEnv } from '../../utils/utils';
import axios from 'axios';

test.describe(apps.dawarich.title, () => {
    for (const instance of apps.dawarich.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            const validUsers = [
                {
                    email: 'homelab-test@homelab.matejhome.com',
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful login - User ${user.email.split('@')[0]}`, async ({ page }) => {
                    await page.goto(`${instance.url}/users/sign_in`);
                    await page.locator('input#user_email[type="email"]').fill(user.email);
                    await page.locator('input#user_password[type="password"]').fill(getEnv(instance.url, `${user.email.split('@')[0]}_PASSWORD`));
                    await page.locator('input[type="submit"][value="Log in"]').click();
                    await expect(page).toHaveURL(`${instance.url}/map`);
                    await expect(page.locator('#map')).toBeVisible();
                });
            }

            const invalidUsers = [
                {
                    title: 'User test',
                    email: 'homelab-test@homelab.matejhome.com',
                },
                {
                    title: 'Random user',
                    email: `${faker.string.alpha(10)}@homelab.matejhome.com`,
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful login - ${user.title}`, async ({ page }) => {
                    await page.goto(`${instance.url}/users/sign_in`);
                    await page.locator('input#user_email[type="email"]').fill(user.email);
                    await page.locator('input#user_password[type="password"]').fill(faker.string.alpha(10));
                    await page.locator('input[type="submit"][value="Log in"]').click();
                    await expect(page.locator('#flash-messages')).toContainText('Invalid Email or password.');
                    await expect(page).toHaveURL(`${instance.url}/users/sign_in`);
                });
            }

            test('API: Prometheus metrics content', async () => {
                const response = await axios.get(`${instance.url}/metrics`, {
                    auth: {
                        username: 'prometheus',
                        password: getEnv(instance.url, 'PROMETHEUS_PASSWORD'),
                    },
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
                const content = response.data as string;
                await test.info().attach('prometheus.txt', { contentType: 'text/plain', body: content });
                const lines = content.split('\n');
                const metrics = [
                    'ruby_http_request_duration_seconds',
                    'ruby_http_requests_total',
                ];
                for (const metric of metrics) {
                    expect(lines.find((el) => el.startsWith(metric)), `Metric ${metric}`).toBeDefined();
                }
            });
        });
    }
});
