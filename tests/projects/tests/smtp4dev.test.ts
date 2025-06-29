import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { getEnv } from '../../utils/utils';
import { faker } from '@faker-js/faker';

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
            createFaviconTests(instance.url, {
                headers: {
                    Authorization: `Basic ${Buffer.from(`admin:${getEnv(instance.url, 'ADMIN_PASSWORD')}`).toString('base64')}`
                },
            });

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
                    test(`UI: Successful open - User ${variant.username}`, async ({ page }) => {
                        await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${variant.username}:${getEnv(instance.url, 'ADMIN_PASSWORD')}`).toString('base64')}` });
                        await page.goto(instance.url);
                        await expect(page.locator('#tab-messages')).toBeVisible({ timeout: 5000 });
                    });
                }

                test(`UI: Unsuccessful open - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.setExtraHTTPHeaders({ Authorization: `Basic ${Buffer.from(`${variant.username}:${faker.string.alphanumeric(10)}`).toString('base64')}` });
                    try {
                        await page.goto(instance.url);
                    } catch {
                        // Ignore error
                    }
                    await expect(page.locator('#tab-messages')).not.toBeVisible({ timeout: 5000 });
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
        });
    }
});
