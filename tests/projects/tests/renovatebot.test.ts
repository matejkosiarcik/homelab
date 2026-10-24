import { pbkdf2 } from 'node:crypto';
import { promisify } from 'node:util';
import { expect, test } from '#/playwright/test.ts';
import { apps } from '#/utils/apps.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '#/utils/tests.ts';
import { axios, getEnv } from '#/utils/utils.ts';
import { faker } from '@faker-js/faker';

const app = apps.renovatebot;

interface RunWispSession {
    readonly readOnly: boolean;
    readonly token: string;
}

async function createRunWispSession(url: string, password: string): Promise<RunWispSession> {
    const pbkdf2Async = promisify(pbkdf2);

    const challenge = await axios.get<{ nonce: string }>(`${url}/api/auth/challenge`);
    expect(challenge.status, 'Challenge response status').toStrictEqual(200);
    expect(challenge.data.nonce, 'Challenge nonce').toBeTruthy();

    const response = (await pbkdf2Async(password, challenge.data.nonce, 600_000, 32, 'sha256')).toString('hex');
    const login = await axios.post<RunWispSession>(`${url}/api/auth/login`, {
        nonce: challenge.data.nonce,
        response: response,
    });
    expect(login.status, 'Login response status').toStrictEqual(200);
    expect(login.data.token, 'Session token').toBeTruthy();

    return login.data;
}

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

            test('API: Validate permissions for unauthenticated access', async () => {
                await test.step('Attempt to get list of tasks', async () => {
                    const response = await axios.get(`${instance.url}/api/tasks`);
                    expect(response.status, 'Response status').toStrictEqual(401);
                });

                await test.step.soft('Attempt to trigger a new run', async () => {
                    const response = await axios.post(`${instance.url}/api/tasks/renovate/run`, {});
                    expect(response.status, 'Read-only task trigger response').toStrictEqual(403);
                });
            });

            test('API: Validate admin permissions', async () => {
                const session = await test.step('Login', async () => {
                    const session = await createRunWispSession(instance.url, getEnv(instance.url, 'RUNWISP_ADMIN_PASSWORD'));
                    expect(session.readOnly, 'Admin session must not be read-only').toStrictEqual(false);
                    return session;
                });

                await test.step('Validate auth', async () => {
                    const authStatus = await axios.get<{ authenticated: boolean; authRequired: boolean; readOnly: boolean }>(`${instance.url}/api/auth/status`, {
                        headers: { Cookie: `runwisp_jwt=${session.token}` },
                    });
                    expect(authStatus.status, 'Authentication status response').toStrictEqual(200);
                    expect(authStatus.data.authRequired, 'Authentication must be enabled').toStrictEqual(true);
                    expect(authStatus.data.authenticated, 'Admin session must be authenticated').toStrictEqual(true);
                    expect(authStatus.data.readOnly, 'Admin session must not be read-only').toStrictEqual(false);
                });

                await test.step.soft('Request server tasks', async () => {
                    const response = await axios.get(`${instance.url}/api/tasks`, {
                        headers: { Authorization: `Bearer ${session.token}` },
                    });
                    expect(response.status, 'Tasks response status').toStrictEqual(200);
                });
            });

            test('API: Validate viewer permissions', async () => {
                const session = await test.step('Login', async () => {
                    const session = await createRunWispSession(instance.url, getEnv(instance.url, 'RUNWISP_VIEWER_PASSWORD'));
                    expect(session.readOnly, 'Viewer session must be read-only').toStrictEqual(true);
                    return session;
                });

                await test.step('Validate auth', async () => {
                    const authStatus = await axios.get<{ authenticated: boolean; authRequired: boolean; readOnly: boolean }>(`${instance.url}/api/auth/status`, {
                        headers: { Cookie: `runwisp_jwt=${session.token}` },
                    });
                    expect(authStatus.status, 'Authentication status response').toStrictEqual(200);
                    expect(authStatus.data.authRequired, 'Authentication must be enabled').toStrictEqual(true);
                    expect(authStatus.data.authenticated, 'Viewer session must be authenticated').toStrictEqual(true);
                    expect(authStatus.data.readOnly, 'Viewer session must be read-only').toStrictEqual(true);
                });

                await test.step.soft('Request server tasks', async () => {
                    const tasks = await axios.get(`${instance.url}/api/tasks`, {
                        headers: { Authorization: `Bearer ${session.token}` },
                    });
                    expect(tasks.status, 'Tasks response status').toStrictEqual(200);
                });

                await test.step.soft('Attempt to trigger a new run', async () => {
                    const response = await axios.post(`${instance.url}/api/tasks/renovate/run`, {}, {
                        headers: { Authorization: `Bearer ${session.token}` },
                    });
                    expect(response.status, 'Read-only task trigger response').toStrictEqual(403);
                });
            });

            test('API: Prometheus metrics content', async () => {
                const response = await test.step('Request metrics', async () => {
                    const response = await axios.get(`${instance.url}/metrics`, {
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
                        'runwisp_runs_total',
                        'runwisp_runs_last_failure_timestamp_seconds',
                        'runwisp_task_active_runs',
                        'runwisp_task_cpu_percent',
                        'runwisp_task_memory_bytes',
                        'runwisp_daemon_cpu_percent',
                        'runwisp_daemon_memory_used_bytes',
                        'runwisp_daemon_memory_total_bytes',
                        'runwisp_daemon_uptime_seconds',
                        'runwisp_build_inf',
                    ];
                    for (const metric of metrics) {
                        expect(lines.find((el) => el.startsWith(metric)), `Metric ${metric}`).toBeDefined();
                    }
                });
            });

            const validUsers = [
                {
                    username: 'admin',
                },
                {
                    username: 'viewer',
                },
            ];
            for (const user of validUsers) {
                test(`UI: Successful login - User ${user.username}`, async ({ page }) => {
                    await test.step('Open login', async () => {
                        await page.goto(instance.url);
                    });

                    await test.step('Login', async () => {
                        await expect(page.locator('#app-sidebar')).not.toBeVisible();
                        await page.locator('input[name="password"]').fill(getEnv(instance.url, `RUNWISP_${user.username}_PASSWORD`));
                        await page.locator('button[type="submit"]').click();
                    });

                    await test.step('Validate login', async () => {
                        await expect(page.locator('#app-sidebar')).toBeVisible();
                    });
                });
            }

            const invalidUsers = [
                {
                    username: 'admin',
                },
            ];
            for (const user of invalidUsers) {
                test(`UI: Unsuccessful login with wrong password - User ${user.username}`, async ({ page }) => {
                    await test.step('Open login', async () => {
                        await page.goto(instance.url);
                    });

                    await test.step('Login', async () => {
                        await page.locator('input[name="password"]').fill(faker.string.alphanumeric(10));
                        await expect(page.locator('#app-sidebar')).not.toBeVisible();
                        await expect(page.locator('text="Invalid password. Please try again."')).not.toBeVisible();
                        await page.locator('button[type="submit"]').click();
                    });

                    await test.step('Validate login attempt', async () => {
                        await expect(page.locator('text="Invalid password. Please try again."')).toBeVisible();
                        await expect(page.locator('#app-sidebar')).not.toBeVisible();
                    });
                });
            }
        });
    }
});
