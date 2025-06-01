import fs from 'node:fs';
import fsx from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { execa } from 'execa';
import { apps } from '../../utils/apps';
import { axios, extractTar, getEnv } from '../../utils/utils';
import { createApiRootTest, createHttpToHttpsRedirectTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps.certbot.title, () => {
    for (const instance of apps.certbot.instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createApiRootTest(instance.url, { status: 404 });
            createTcpTests(instance.url, [80, 443]);

            test(`API: HTTPS redirect for certificate`, async () => {
                const response = await axios.get(`${instance.url.replace('https://', 'http://')}/download/certificate.tar.xz`, { maxRedirects: 0 });
                expect(response.status, 'Response Status').toStrictEqual(302);
                expect(response.headers['location'], 'Response Header Location').toStrictEqual(`${instance.url.replace('http://', 'https://')}/download/certificate.tar.xz`);
            });

            test(`API: HTTPS redirect for random download subpath`, async () => {
                const randomSubpath = faker.string.alphanumeric(10);
                const response = await axios.get(`${instance.url.replace('https://', 'http://')}/download/${randomSubpath}`, { maxRedirects: 0 });
                expect(response.status, 'Response Status').toStrictEqual(302);
                expect(response.headers['location'], 'Response Header Location').toStrictEqual(`${instance.url.replace('http://', 'https://')}/download/${randomSubpath}`);
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
                        username: 'viewer',
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
                test(`API: Read certificate (${variant.title})`, async () => {
                    const response = await axios.get(`${instance.url}/download/certificate.tar.xz`, { auth: variant.auth });
                    expect(response.status, 'Response Status').toStrictEqual(variant.status);
                });

                test(`API: Read random download subpath (${variant.title})`, async () => {
                    const response = await axios.get(`${instance.url}/download/${faker.string.alpha(10)}`, { auth: variant.auth });
                    expect(response.status, 'Response Status').toStrictEqual(variant.status === 200 ? 404 : variant.status);
                });
            }

            test('API: Read and validate certificate', async () => {
                const response = await axios.get(`${instance.url}/download/certificate.tar.xz`, {
                    decompress: false,
                    responseType: 'arraybuffer',
                    auth: {
                        username: 'viewer',
                        password: getEnv(instance.url, 'VIEWER_PASSWORD'),
                    },
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
                const randomDir = (await fsx.mkdtemp(path.join(os.tmpdir(), 'homelab-')))!;
                try {
                    await fsx.writeFile(path.join(randomDir, 'certificate.tar.xz'), response.data, { encoding: 'binary' });

                    const certificateDir = path.join(randomDir, 'certificate');
                    await fsx.mkdir(certificateDir);
                    await extractTar(path.join(randomDir, 'certificate.tar.xz'), certificateDir);
                    const certificateFile = path.join(randomDir, 'certificate', 'fullchain.pem');

                    expect(fs.existsSync(path.join(certificateDir, 'cert.pem')), 'File cert.pem should exist').toStrictEqual(true);
                    expect(fs.existsSync(path.join(certificateDir, 'chain.pem')), 'File chain.pem should exist').toStrictEqual(true);
                    expect(fs.existsSync(path.join(certificateDir, 'fullchain.pem')), 'File fullchain.pem should exist').toStrictEqual(true);
                    expect(fs.existsSync(path.join(certificateDir, 'privkey.pem')), 'File privkey.pem should exist').toStrictEqual(true);
                    expect(fs.existsSync(path.join(certificateDir, 'README')), 'File README should exist').toStrictEqual(true);

                    const subprocess = await execa('openssl', ['x509', '-noout', '-subject', '-in', certificateFile]);
                    expect(subprocess.exitCode, 'OpenSSL subject exit code').toStrictEqual(0);
                    const domain = subprocess.stdout.trim().replace(/^subject\s*=\s*CN\s*=\s*/, '');
                    expect(domain, 'OpenSSL exit code').toStrictEqual('*.home.matejkosiarcik.com');

                    const subprocess2 = await execa('openssl', ['x509', '-noout', '-checkend', (60 * 60 * 24 * 30).toFixed(0), '-in', certificateFile]);
                    expect(subprocess2.exitCode, 'OpenSSL validity exit code').toStrictEqual(0);
                } finally {
                    await fsx.rm(randomDir, { recursive: true, force: true });
                }
            });
        });
    }
});
