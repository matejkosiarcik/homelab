import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';
import { getEnv } from '../../utils/utils';
import { faker } from '@faker-js/faker';
import axios from 'axios';

test.describe(apps.ollama.title, () => {
    for (const instance of apps.ollama.instances) {
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
                    const response = await axios.get(`${instance.url}/`, {
                        auth: {
                            username: user.username,
                            password: faker.string.alpha(10),
                        },
                        validateStatus: () => true,
                    });
                    expect(response.status, 'Response Status').toStrictEqual(401);
                });
            }

            // TODO: Add tests for API endpoints
        });
    }
});
