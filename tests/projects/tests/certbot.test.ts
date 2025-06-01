import fsx from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { apps } from '../../utils/apps';
import { axios, extractTar, getEnv } from '../../utils/utils';
import { createApiRootTest, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps.certbot.title, () => {
    for (const instance of apps.certbot.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url, { status: 403 });
            createTcpTests(instance.url, [80, 443]);

            test(`API: HTTPS redirect for certificate`, async () => {
                const response = await axios.get(`${instance.url.replace('https://', 'http://')}/download/certificate.tar.xz`, { maxRedirects: 0 });
                expect(response.status, 'Response Status').toStrictEqual(302);
                expect(response.headers['location'], 'Response Header Location').toStrictEqual(`${instance.url.replace('http://', 'https://')}/download/certificate.tar.xz`);
            });

            const dataVariants = [
                {
                    title: 'no credentials',
                    auth: undefined as unknown as { username: string, password: string },
                    status: 401,
                },
                {
                    title: 'empty password',
                    auth: {
                        username: 'certificate-loader',
                        password: '',
                    },
                    status: 401,
                },
                {
                    title: 'wrong password',
                    auth: {
                        username: 'viewer',
                        password: faker.string.alphanumeric(10),
                    },
                    status: 401,
                },
                {
                    title: 'wrong username/password',
                    auth: {
                        username: faker.string.alphanumeric(10),
                        password: faker.string.alphanumeric(10),
                    },
                    status: 401,
                },
                {
                    title: 'successful',
                    auth: {
                        username: 'viewer',
                        password: getEnv(instance.url, 'VIEWER_PASSWORD'),
                    },
                    status: 200,
                },
            ];
            for (const variant of dataVariants) {
                test(`API: Read certificates (${variant.title})`, async () => {
                    const response = await axios.get(`${instance.url}/download/certificate.tar.xz`, { auth: variant.auth });
                    expect(response.status, 'Response Status').toStrictEqual(variant.status);
                });
            }

            test('API: Read and validate certificates', async () => {
                const response = await axios.get(`${instance.url}/download/certificate.tar.xz`, {
                    auth: {
                        username: 'viewer',
                        password: getEnv(instance.url, 'VIEWER_PASSWORD'),
                    },
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
                const randomDir = (await fsx.mkdir(path.join(os.tmpdir(), 'homelab-'), { recursive: true }))!;
                try {
                    await fsx.writeFile(path.join(randomDir, 'certificate.tar.xz'), response.data, { encoding: 'binary' });
                    await extractTar(path.join(randomDir, 'certificate.tar.xz'), path.join(randomDir, 'certificate'));
                    // TODO: Validate extracted certificate
                } finally {
                    await fsx.rm(randomDir, { recursive: true, force: true });
                }
            });
        });
    }
});
