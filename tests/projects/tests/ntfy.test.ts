import { faker } from '@faker-js/faker';
import { expect, test } from '#/playwright/test.ts';
import { apps } from '#/utils/apps.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '#/utils/tests.ts';
import { axios, delay, getEnv, waitForHidden } from '#/utils/utils.ts';

const app = apps.ntfy;

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

            test('UI: Open', async ({ page }) => {
                await test.step('Open application', async () => {
                    await page.goto(instance.url);
                });

                await test.step('Validate application', async () => {
                    await expect(page.locator('text="All notifications"').first()).toBeVisible({ timeout: 5000 });
                });
            });

            const validUsers = [
                {
                    username: 'matej',
                },
                {
                    username: 'homelab-test',
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful login - User ${user.username}`, async ({ page }) => {
                    await test.step('Open login', async () => {
                        await delay(2500); // Must delay tests a bit
                        await page.goto(instance.url);
                        await waitForHidden(page.locator('#splash'));
                        await page.getByRole('button', { name: 'Subscribe to topic', exact: true }).click();
                        await page.locator('.MuiDialogContent-root input#topic').fill('test');
                        await delay(100);
                        await page.locator('.MuiDialogActions-root button:has-text("Subscribe")').click();
                    });

                    await test.step('Login', async () => {
                        await page.locator('.MuiDialogContent-root input#username').fill(user.username);
                        await page.locator('.MuiDialogContent-root input#password').fill(getEnv(instance.url, `${user.username}_PASSWORD`));
                        await delay(250);
                        await page.locator('.MuiDialogActions-root button:has-text("Login")').click({ timeout: 4000 });
                    });

                    await test.step('Validate login', async () => {
                        await page.waitForURL(`${instance.url}/test`);
                        await expect(page.locator('.MuiFormControl-root input[placeholder="Type a message here"]')).toBeVisible();
                    });
                });

                test(`API+UI: Send notification in homelab-publisher and view in ${user.username}`, async ({ page }) => {
                    const notification = faker.string.alphanumeric(30);

                    await test.step('Open subscription', async () => {
                        await delay(2500); // Must delay tests a bit
                        await page.goto(instance.url);
                        await waitForHidden(page.locator('#splash'));
                        await page.getByRole('button', { name: 'Subscribe to topic', exact: true }).click();
                        await page.locator('.MuiDialogContent-root input#topic').fill('test');
                        await delay(100);
                        await page.locator('.MuiDialogActions-root button:has-text("Subscribe")').click();
                    });

                    await test.step('Login', async () => {
                        await page.locator('.MuiDialogContent-root input#username').fill(user.username);
                        await page.locator('.MuiDialogContent-root input#password').fill(getEnv(instance.url, `${user.username}_PASSWORD`));
                        await delay(100);
                        await page.locator('.MuiDialogActions-root button:has-text("Login")').click();
                    });

                    await test.step('Validate login', async () => {
                        await page.waitForURL(`${instance.url}/test`);
                        await expect(page.locator('.MuiFormControl-root input[placeholder="Type a message here"]')).toBeVisible();
                    });

                    await test.step('Send notification', async () => {
                        await expect(page.locator(`.MuiCardContent-root:has-text("${notification}")`)).not.toBeVisible();
                        const response = await axios.request({
                            auth: {
                                username: 'homelab-publisher',
                                password: getEnv(instance.url, 'HOMELAB_PUBLISHER_PASSWORD'),
                            },
                            data: notification,
                            maxRedirects: 0,
                            method: 'POST',
                            url: `${instance.url}/test`,
                        });
                        expect(response.status, 'Response Status').toStrictEqual(200);
                    });

                    await test.step('Validate notification', async () => {
                        await expect(page.locator(`.MuiCardContent-root:has-text("${notification}")`)).toBeVisible();
                    });

                    await test.step('Dismiss notification', async () => {
                        await delay(500);
                        await page.locator(`.MuiCardContent-root:has-text("${notification}") button:has([data-testid="CloseIcon"])`).click();
                        await expect(page.locator(`.MuiCardContent-root:has-text("${notification}")`)).not.toBeVisible();
                    });
                });
            }

            const invalidViewerUsers = [
                {
                    username: 'homelab-test',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                },
            ];
            for (const user of invalidViewerUsers) {
                test(`UI: Unsuccessful login - ${user.random ? 'Random user' : `User ${user.username}`}`, async ({ page }) => {
                    const originalUrl = await test.step('Open login', async () => {
                        await delay(2500); // Must delay tests a bit
                        await page.goto(instance.url);
                        await waitForHidden(page.locator('#splash'));
                        const loginUrl = page.url();
                        await page.getByRole('button', { name: 'Subscribe to topic', exact: true }).click();
                        await page.locator('.MuiDialogContent-root input#topic').fill('test');
                        await delay(100);
                        await page.locator('.MuiDialogActions-root button:has-text("Subscribe")').click();
                        return loginUrl;
                    });

                    await test.step('Attempt login', async () => {
                        await page.locator('.MuiDialogContent-root input#username').fill(user.username);
                        await page.locator('.MuiDialogContent-root input#password').fill(faker.string.alpha(10));
                        await delay(100);
                        await page.locator('.MuiDialogActions-root button:has-text("Login")').click();
                    });

                    await test.step('Validate login attempt', async () => {
                        await expect(page.locator('.MuiDialog-container')).toContainText(`User ${user.username} not authorized`);
                        await expect(page, 'URL should not change').toHaveURL(originalUrl);
                    });
                });
            }

            const invalidPublisherUsers2 = [
                {
                    username: 'homelab-test',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                },
            ];
            for (const user of invalidPublisherUsers2) {
                test(`API: Unsuccessful send notification - ${user.random ? 'Random user' : `User ${user.username}`}`, async () => {
                    await delay(2500); // Must delay tests a bit
                    await test.step('Request server', async () => {
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
                });
            }
        });
    }
});
