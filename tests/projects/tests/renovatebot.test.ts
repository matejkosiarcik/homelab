import { test } from '@playwright/test';
import { apps } from '../../utils/apps.ts';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests.ts';
import { getEnv } from '../../utils/utils.ts';

const app = apps.renovatebot;

test.describe(app.title, () => {
    for (const instance of app.instances) {
        if ('enabled' in instance && instance.enabled === false) {
            test.skip(`Instance ${app.title} ${instance.title} is disabled`, () => {});
            continue;
        }

        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
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
            }
        });
    }
});
