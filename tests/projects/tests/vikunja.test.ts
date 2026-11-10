import { faker } from '@faker-js/faker';
import { expect, test } from '#/playwright/test.ts';
import { apps } from '#/utils/apps.ts';
import { axios } from '#/utils/axios.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '#/utils/tests.ts';
import { getEnv } from '#/utils/utils.ts';

const app = apps.vikunja;

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
            createPrometheusTests(instance.url, { auth: 'basic', path: '/api/v1/metrics' });

            test('API: Service info', async () => {
                const response = await test.step('Request server', async () => {
                    const response = await axios.get(`${instance.url}/api/v1/info`);
                    expect(response.status, 'Response Status').toStrictEqual(200);
                    return response;
                });

                await test.step('Validate response', async () => {
                    const body = response.data as { version: string, frontend_url: string };
                    expect(body.version, 'Response version').toMatch(/^v\d+\.\d+\.\d+$/);
                    expect(body.frontend_url, 'Response frontend_url').toStrictEqual(`${instance.url}/`);
                });
            });

            test('API: Prometheus metrics content', async () => {
                const response = await test.step('Request server', async () => {
                    const response = await axios.get(`${instance.url}/api/v1/metrics`, {
                        auth: {
                            username: 'prometheus',
                            password: getEnv(instance.url, 'PROMETHEUS_PASSWORD'),
                        },
                    });
                    expect(response.status, 'Response Status').toStrictEqual(200);
                    return response;
                });

                await test.step('Validate response', async () => {
                    const content = response.data as string;
                    await test.info().attach('prometheus.txt', { contentType: 'text/plain', body: content });
                    const lines = content.split('\n');
                    const metrics = [
                        'vikunja_active_link_shares',
                        'vikunja_active_users',
                        'vikunja_attachments_count',
                        'vikunja_files_count',
                        'vikunja_project_count',
                        'vikunja_task_count',
                        'vikunja_team_count',
                        'vikunja_user_count',
                    ];
                    for (const metric of metrics) {
                        expect(lines.find((el) => el.startsWith(metric)), `Metric ${metric}`).toBeDefined();
                    }
                });
            });


            const validUsers = [
                {
                    username: 'homelab-test',
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful login - User ${user.username}`, async ({ page }) => {
                    await test.step('Open login', async () => {
                        await page.goto(instance.url);
                        await page.waitForURL(`${instance.url}/login`);
                        await expect(page.locator('form#loginform')).toBeVisible();
                    });

                    await test.step('Login', async () => {
                        await page.locator('form#loginform input#username').fill(user.username);
                        await page.locator('form#loginform input#password').fill(getEnv(instance.url, `${user.username}_PASSWORD`));
                        await page.locator('form#loginform button[type="button"]:has-text("Login")').click({ noWaitAfter: true });
                    });

                    await test.step('Validate successful login', async () => {
                        await expect(page.locator('aside li .project-menu-title:has-text("Inbox")')).toBeVisible();
                    });
                });
            }

            const invalidUsers = [
                {
                    username: 'homelab-test',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful login - ${user.random ? 'Random user' : `User ${user.username}`}`, async ({ page }) => {
                    const originalUrl = await test.step('Open login', async () => {
                        await page.goto(instance.url);
                        await page.waitForURL(`${instance.url}/login`);
                        await expect(page.locator('form#loginform')).toBeVisible();
                        return page.url();
                    });

                    await test.step('Attempt login', async () => {
                        // For loop necessary to overcome flakiness
                        for (let i = 0; i < 2; i++) {
                            await page.locator('form#loginform input#username').fill(user.username);
                            await page.locator('form#loginform input#password').fill(faker.string.alphanumeric(10));
                            await page.locator('form#loginform button[type="button"]:has-text("Login")').click({ noWaitAfter: true });

                            try {
                                await expect(page.locator('.message:has-text("Wrong username or password.")')).toBeVisible();
                                await expect(page, 'URL should not change').toHaveURL(originalUrl);
                            } catch {
                                continue;
                            }
                            break;
                        }
                    });

                    await test.step('Validate unsuccessful login', async () => {
                        await expect(page.locator('.message:has-text("Wrong username or password.")')).toBeVisible();
                        await expect(page, 'URL should not change').toHaveURL(originalUrl);
                    });
                });
            }
        });
    }
});
