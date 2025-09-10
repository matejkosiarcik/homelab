import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { axios, delay, getEnv } from '../../utils/utils';

test.describe(apps.ntfy.title, () => {
    for (const instance of apps.ntfy.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            test('UI: Open', async ({ page }) => {
                await page.goto(instance.url);
                await expect(page.locator('text="All notifications"').first()).toBeVisible({ timeout: 5000 });
            });

            for (const user of [
                {
                    title: 'User test',
                    username: 'user',
                },
            ]) {
                test(`UI: Successful login - User ${user.title}`, async ({ page }) => {
                    await delay(2500); // Must delay tests a bit
                    await page.goto(instance.url);
                    await page.locator('.MuiDrawer-root .MuiListItemText-root:has-text("Subscribe to topic")').first().click();
                    await page.locator('.MuiDialogContent-root input#topic').fill('test');
                    await delay(100);
                    await page.locator('.MuiDialogActions-root button:has-text("Subscribe")').click();
                    await page.locator('.MuiDialogContent-root input#username').fill(user.username);
                    await page.locator('.MuiDialogContent-root input#password').fill(getEnv(instance.url, `${user.username}_PASSWORD`));
                    await delay(250);
                    await page.locator('.MuiDialogActions-root button:has-text("Login")').click({ timeout: 4000 });
                    await page.waitForURL(`${instance.url}/test`);
                    await expect(page.locator('.MuiFormControl-root input[placeholder="Type a message here"]')).toBeVisible();
                });
            }

            for (const user of [
                {
                    title: 'User test',
                    username: 'user',
                },
                {
                    title: 'Random user',
                    username: faker.string.alpha(10),
                }
            ]) {
                test(`UI: Unsuccessful login - ${user.title}`, async ({ page }) => {
                    await delay(2500); // Must delay tests a bit
                    await page.goto(instance.url);
                    await page.locator('.MuiDrawer-root .MuiListItemText-root:has-text("Subscribe to topic")').first().waitFor()
                    const originalUrl = page.url();
                    await page.locator('.MuiDrawer-root .MuiListItemText-root:has-text("Subscribe to topic")').first().click();
                    await page.locator('.MuiDialogContent-root input#topic').fill('test');
                    await delay(100);
                    await page.locator('.MuiDialogActions-root button:has-text("Subscribe")').click();
                    await page.locator('.MuiDialogContent-root input#username').fill(user.username);
                    await page.locator('.MuiDialogContent-root input#password').fill(faker.string.alpha(10));
                    await delay(100);
                    await page.locator('.MuiDialogActions-root button:has-text("Login")').click();
                    await expect(page.locator('.MuiDialog-container')).toContainText(`User ${user.username} not authorized`);
                    await expect(page, 'URL should not change').toHaveURL(originalUrl);
                });
            }

            for (const user of [
                {
                    username: 'publisher',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                }
            ]) {
                test(`API: Unsuccessful send notification  - ${user.random ? 'Random user' : `User ${user.username}`}`, async () => {
                    await delay(2500); // Must delay tests a bit
                    const response = await axios.request({
                        auth: {
                            username: user.username,
                            password: faker.string.alpha(10),
                        },
                        data: faker.string.alphanumeric(30),
                        maxRedirects: 0,
                        method: 'POST',
                        url: `${instance.url}/test`,
                    });
                    expect(response.status, 'Response Status').toStrictEqual(401);
                });
            }

            for (const user of [
                {
                    username: 'user',
                },
            ]) {
                test(`API+UI: Send notification in "publisher" and view in "${user.username}"`, async ({ page }) => {
                    await delay(2500); // Must delay tests a bit
                    await page.goto(instance.url);
                    await page.locator('.MuiDrawer-root .MuiListItemText-root:has-text("Subscribe to topic")').first().click();
                    await page.locator('.MuiDialogContent-root input#topic').fill('test');
                    await delay(100);
                    await page.locator('.MuiDialogActions-root button:has-text("Subscribe")').click();
                    await page.locator('.MuiDialogContent-root input#username').fill(user.username);
                    await page.locator('.MuiDialogContent-root input#password').fill(getEnv(instance.url, `${user.username}_PASSWORD`));
                    await delay(100);
                    await page.locator('.MuiDialogActions-root button:has-text("Login")').click();
                    await page.waitForURL(`${instance.url}/test`);
                    await expect(page.locator('.MuiFormControl-root input[placeholder="Type a message here"]')).toBeVisible();

                    const notification = faker.string.alphanumeric(30);
                    await expect(page.locator(`.MuiCardContent-root:has-text("${notification}")`)).not.toBeVisible();

                    const response = await axios.request({
                        auth: {
                            username: user.username,
                            password: getEnv(instance.url, `${user.username}_PASSWORD`),
                        },
                        data: notification,
                        maxRedirects: 0,
                        method: 'POST',
                        url: `${instance.url}/test`,
                    });
                    expect(response.status, 'Response Status').toStrictEqual(200);

                    await expect(page.locator(`.MuiCardContent-root:has-text("${notification}")`)).toBeVisible();
                    await delay(500);
                    await page.locator(`.MuiCardContent-root:has-text("${notification}") button:has([data-testid="CloseIcon"])`).click();
                    await expect(page.locator(`.MuiCardContent-root:has-text("${notification}")`)).not.toBeVisible();
                });
            }
        });
    }
});
