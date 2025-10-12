import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { faker } from '@faker-js/faker';
import { getEnv } from '../../utils/utils';

test.describe(apps.grafana.title, () => {
    for (const instance of apps.grafana.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            // TODO: createPrometheusTests(instance.url, { auth: 'basic' });
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            for (const user of [
                {
                    username: 'homelab-test',
                },
            ]) {
                test(`UI: Successful open - User test`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${user.username}:${getEnv(instance.url, `${user.username}_PASSWORD`)}`).toString('base64')}` });
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/login`);
                    await page.locator('input[name="user"]').waitFor({ timeout: 6000 });
                    await page.locator('input[name="user"]').fill(user.username);
                    await page.locator('input[name="password"]').fill(getEnv(instance.url, `${user.username}_PASSWORD`));
                    await page.locator('button[type=submit]').click();
                    await expect(page.locator('button[aria-label="Profile"]')).toBeVisible({ timeout: 6000 });
                });
            }

            for (const user of [
                {
                    title: 'User homelab-test',
                    username: 'homelab-test',
                },
                {
                    title: 'Random user',
                    username: faker.string.alpha(10),
                },
            ]) {
                test(`UI: Unsuccessful login - ${user.title}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(`${instance.url}/login`);
                    const originalUrl = page.url();
                    await page.locator('input[name="user"]').waitFor({ timeout: 6000 });
                    await page.locator('input[name="user"]').fill(user.username);
                    await page.locator('input[name="password"]').fill(faker.string.alpha(10));
                    await page.locator('button[type=submit]').click();
                    await expect(page.locator('.login-content-box:has-text("Login failed")')).toBeVisible();
                    await expect(page.locator('.login-content-box:has-text("Invalid username or password")')).toBeVisible();
                    await expect(page, 'URL should not change').toHaveURL(originalUrl);
                });
            }
        });
    }
});
