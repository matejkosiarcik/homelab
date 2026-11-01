import { expect, test } from '#/playwright/test.ts';
import { apps } from '#/utils/apps.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '#/utils/tests.ts';
import { axios, getEnv } from '#/utils/utils.ts';
import { faker } from '@faker-js/faker';

const app = apps.ollama;

test.describe(app.title, () => {
    for (const instance of app.instances) {
        if ('enabled' in instance && instance.enabled === false) {
            test.skip(`Instance ${app.title} ${instance.title} is disabled`, () => {});
            continue;
        }

        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            // TODO: createPrometheusTests(instance.url, { auth: 'basic' });
            createProxyTests(instance.url);
            createApiRootTest(instance.url, { title: 'Unauthenticated', status: 401 });
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            const validUsers = [
                {
                    username: 'matej',
                },
                {
                    username: 'homelab-viewer',
                },
                {
                    username: 'homelab-test',
                },
            ];
            for (const user of validUsers) {
                createApiRootTest(instance.url, {
                    title: `Authenticated - User ${user.username}`,
                    headers: {
                        Authorization: `Basic ${Buffer.from(`${user.username}:${getEnv(instance.url, `${user.username}_PASSWORD`)}`).toString('base64')}`
                    },
                });

                test(`API: List models - User ${user.username}`, async () => {
                    const response = await test.step('Request server', async () => {
                        const response = await axios.get(`${instance.url}/api/tags`, {
                            auth: {
                                username: user.username,
                                password: getEnv(instance.url, `${user.username}_PASSWORD`),
                            },
                        });
                        expect(response.status, 'Response Status').toStrictEqual(200);
                        return response;
                    });

                    await test.step('Validate response', async () => {
                        const body = response.data as { models: { name: string, model: string, modified_at: string, size: number, digest: string, details: unknown, capabilities: unknown[] }[] };
                        expect(body.models, 'Response models').toBeInstanceOf(Array);
                        expect(body.models.length, 'Response models length').toBeGreaterThan(0);
                        for (const model of body.models) {
                            expect(model.name, 'Response model name').toMatch(/^[\w.-]+:[\w.-]+$/);
                            expect(model.model, 'Response model model').toMatch(/^[\w.-]+:[\w.-]+$/);
                            expect(model.modified_at, 'Response model modified_at').toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z$/);
                            expect(model.size, 'Response model size').toBeGreaterThan(0);
                            expect(model.digest, 'Response model digest').toMatch(/^[\da-f]+$/);
                            expect(model.details, 'Response model details').toBeDefined();
                            expect(model.capabilities, 'Response model capabilities').toBeInstanceOf(Array);
                        }
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
                test(`API: Unsuccessful get root - ${user.random ? 'Random user' : `User ${user.username}`}`, async () => {
                    await test.step('Request server', async () => {
                        const response = await axios.get(`${instance.url}/`, {
                            auth: {
                                username: user.username,
                                password: faker.string.alpha(10),
                            },
                            validateStatus: () => true,
                        });
                        expect(response.status, 'Response Status').toStrictEqual(401);
                    });
                });
            }

            // TODO: Add tests for API endpoints
        });
    }
});
