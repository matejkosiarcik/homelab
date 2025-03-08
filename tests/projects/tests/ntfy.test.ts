import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createProxyTests, createTcpTest } from '../../utils/tests';
import { getEnv } from '../../utils/utils';

test.describe(apps.ntfy.title, () => {
    for (const instance of apps.ntfy.instances) {
        test.describe(instance.title, () => {
            // TODO: Add test for HTTP->HTTPS redirects after real Let's Encrypt certificates
            createProxyTests(instance.url);

            for (const port of [80, 443]) {
                createTcpTest(instance.url, port);
            }

            test('API: Root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });

            test('UI: Open', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('text="All notifications"').first()).toBeVisible({ timeout: 5000 });
            });
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
                    await page.locator('.MuiDrawer-root .MuiListItemText-root:has-text("Subscribe to topic")').first().click();
                    await page.locator('.MuiDialogContent-root input#topic').fill('test');
                    await page.locator('.MuiDialogActions-root button:has-text("Subscribe")').click();
                    await page.locator('.MuiDialogContent-root input#username').fill(variant.username);
                    await page.locator('.MuiDialogContent-root input#password').fill(getEnv(instance.url, `${variant.username}_PASSWORD`));
                    await page.locator('.MuiDialogActions-root button:has-text("Login")').click();
                    await page.waitForURL(`${instance.url}/test`);
                    await expect(page.locator('.MuiFormControl-root input[placeholder="Type a message here"]')).toBeVisible();
                });
            }

            test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                await page.goto(instance.url);
                await page.locator('.MuiDrawer-root .MuiListItemText-root:has-text("Subscribe to topic")').first().waitFor()
                const originalUrl = page.url();
                await page.locator('.MuiDrawer-root .MuiListItemText-root:has-text("Subscribe to topic")').first().click();
                await page.locator('.MuiDialogContent-root input#topic').fill('test');
                await page.locator('.MuiDialogActions-root button:has-text("Subscribe")').click();
                await page.locator('.MuiDialogContent-root input#username').fill(variant.username);
                await page.locator('.MuiDialogContent-root input#password').fill(faker.string.alpha(10));
                await page.locator('.MuiDialogActions-root button:has-text("Login")').click();
                await expect(page.locator('.MuiDialog-container')).toContainText(`User ${variant.username} not authorized`);
                expect(page.url(), 'URL should not change').toStrictEqual(originalUrl);
            });
        }
    }
});
