import net from 'node:net';
import PromiseSocket from 'promise-socket';
import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { getEnv } from './utils';

export function createTcpTest(url: string, port: number, subtitle?: string | undefined) {
    return test(`TCP: Connect to port ${port}${subtitle ? ` ${subtitle}` : ''}`, async () => {
        const host = url.replace(/^.*?:\/\//, '');
    const socket = new net.Socket();
        const promiseSocket = new PromiseSocket(socket);
        await promiseSocket.connect(port, host);
        await promiseSocket.end();
    });
}

export function createApiRootTest(url: string, _options?: { headers?: Record<string, string> | undefined, title?: string | undefined, status?: number | undefined }) {
    const options = {
        headers: _options?.headers ?? {},
        title: _options?.title ?? '',
        status: _options?.status ?? 200,
    };
    return [
        test(`API: Get root${options.title ? ` - ${options.title}` : ''}`, async () => {
            const response = await axios.get(url, { headers: options.headers, httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999, validateStatus: () => true });
            expect(response.status, 'Response Status').toStrictEqual(options.status);
        }),
    ];
}

export function createHttpToHttpsRedirectTests(url: string) {
    return [
        test('API: Redirect HTTP to HTTPS (root)', async () => {
            const response = await axios.get(url.replace(/^https:\/\//, 'http://'), { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, validateStatus: () => true });
            expect(response.status, 'Response Status').toStrictEqual(302);
            expect(response.headers['location'], 'Response header location').toStrictEqual(url.replace(/^http:\/\//, 'https://'));
        }),

        test('API: Redirect HTTP to HTTPS (root slash)', async () => {
            const response = await axios.get(`${url.replace(/^https:\/\//, 'http://')}/`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, validateStatus: () => true });
            expect(response.status, 'Response Status').toStrictEqual(302);
            expect(response.headers['location'], 'Response header location').toStrictEqual(url.replace(/^http:\/\//, 'https://'));
        }),

        test('API: Redirect HTTP to HTTPS (random subpage)', async () => {
            const subpage = `/${faker.string.alpha(10)}`;
            const response = await axios.get(`${url.replace(/^https:\/\//, 'http://')}${subpage}`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, validateStatus: () => true });
            expect(response.status, 'Response Status').toStrictEqual(302);
            expect(response.headers['location'], 'Response header location').toStrictEqual(`${url.replace(/^http:\/\//, 'https://')}${subpage}`);
        }),
    ];
}

export function createHttpsToHttpRedirectTests(url: string) {
    return [
        test('API: Redirect HTTPS to HTTP (root)', async () => {
            const response = await axios.get(url.replace(/^http:\/\//, 'https://'), { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, validateStatus: () => true });
            expect(response.status, 'Response Status').toStrictEqual(302);
            expect(response.headers['location'], 'Response header location').toStrictEqual(url.replace(/^https:\/\//, 'http://'));
        }),

        test('API: Redirect HTTPS to HTTP (root slash)', async () => {
            const response = await axios.get(`${url.replace(/^http:\/\//, 'https://')}/`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, validateStatus: () => true });
            expect(response.status, 'Response Status').toStrictEqual(302);
            expect(response.headers['location'], 'Response header location').toStrictEqual(url.replace(/^https:\/\//, 'http://'));
        }),

        test('API: Redirect HTTPS to HTTP (random subpage)', async () => {
            const subpage = `/${faker.string.alpha(10)}`;
            const response = await axios.get(`${url.replace(/^http:\/\//, 'https://')}${subpage}`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, validateStatus: () => true });
            expect(response.status, 'Response Status').toStrictEqual(302);
            expect(response.headers['location'], 'Response header location').toStrictEqual(`${url.replace(/^https:\/\//, 'http://')}${subpage}`);
        }),
    ];
}

export function createProxyTests(url: string) {
    const output = [test(`API: Proxy root`, async () => {
        const response = await axios.get(`${url}/.proxy`, {
            maxRedirects: 999,
            validateStatus: () => true,
            httpsAgent: new https.Agent({ rejectUnauthorized: false }),
        });
        expect(response.status, 'Response Status').toStrictEqual(200);
    })];

    const proxyStatusVariants = [
        {
            title: 'no credentials',
            auth: undefined as unknown as { username: string, password: string },
            status: 401,
        },
        {
            title: 'empty password',
            auth: {
                username: 'proxy-status',
                password: '',
            },
            status: 401,
        },
        {
            title: 'wrong password',
            auth: {
                username: 'proxy-status',
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
                username: 'proxy-status',
                password: getEnv(url, 'PROXY_STATUS_PASSWORD'),
            },
            status: 200,
        },
    ];
    output.push(...proxyStatusVariants.map((variant) => {
        return test(`API: Proxy status (${variant.title})`, async () => {
            const response = await axios.get(`${url}/.proxy/status`, {
                auth: variant.auth,
                maxRedirects: 999,
                validateStatus: () => true,
                httpsAgent: new https.Agent({ rejectUnauthorized: false }),
            });
            expect(response.status, 'Response Status').toStrictEqual(variant.status);
        });
    }));

    const proxyPrometheusVariants = [
        {
            title: 'no credentials',
            auth: undefined as unknown as { username: string, password: string },
            status: 401,
        },
        {
            title: 'empty password',
            auth: {
                username: 'proxy-prometheus',
                password: '',
            },
            status: 401,
        },
        {
            title: 'wrong password',
            auth: {
                username: 'proxy-prometheus',
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
                username: 'proxy-prometheus',
                password: getEnv(url, 'PROXY_PROMETHEUS_PASSWORD'),
            },
            status: 200,
        },
    ];
    output.push(...proxyPrometheusVariants.map((variant) => {
        return test(`API: Proxy prometheus metrics (${variant.title})`, async () => {
            const response = await axios.get(`${url}/.proxy/metrics`, {
                auth: variant.auth,
                maxRedirects: 999,
                validateStatus: () => true,
                httpsAgent: new https.Agent({ rejectUnauthorized: false }),
            });
            expect(response.status, 'Response Status').toStrictEqual(variant.status);
        });
    }));

    output.push(
        test('API: Proxy prometheus metrics content', async () => {
            const response = await axios.get(`${url}/.proxy/metrics`, {
                auth: {
                    username: 'proxy-prometheus',
                    password: getEnv(url, 'PROXY_PROMETHEUS_PASSWORD'),
                },
                maxRedirects: 999,
                validateStatus: () => true,
                httpsAgent: new https.Agent({ rejectUnauthorized: false }),
            });
            expect(response.status, 'Response Status').toStrictEqual(200);
            const content = response.data as string;
            await test.info().attach('prometheus.txt', { contentType: 'text/plain', body: content });
            const lines = content.split('\n');
            const metrics = [
                'apache_accesses_total',
                'apache_connections',
                'apache_cpu_time_ms_total',
                'apache_cpuload',
                'apache_duration_ms_total',
                'apache_exporter_build_info',
                'apache_generation',
                'apache_info',
                'apache_load',
                'apache_processes',
                'apache_scoreboard',
                'apache_sent_kilobytes_total',
                'apache_up',
                'apache_uptime_seconds_total',
                'apache_version',
                'apache_workers',
            ];
            for (const metric of metrics) {
                expect(lines.find((el) => el.startsWith(metric)), `Metric ${metric}`).toBeDefined();
            }
        }),
    );

    return output;
}

export function createPrometheusTests(url: string, _options: { auth: 'basic' | 'token'; path?: string | undefined  }) {
    const options = {
        auth: _options.auth,
        path: _options.path ?? '/metrics',
    };

    switch (options.auth) {
        case 'basic': {
            const prometheusVariants = [
                {
                    title: 'no credentials',
                    auth: undefined as unknown as { username: string, password: string },
                    status: 401,
                },
                {
                    title: 'wrong username and password',
                    auth: {
                        username: faker.string.alphanumeric(10),
                        password: faker.string.alphanumeric(10),
                    },
                    status: 401,
                },
                {
                    title: 'wrong password',
                    auth: {
                        username: 'prometheus',
                        password: faker.string.alphanumeric(10),
                    },
                    status: 401,
                },
                {
                    title: 'successful',
                    auth: {
                        username: 'prometheus',
                        password: getEnv(url, 'PROMETHEUS_PASSWORD'),
                    },
                    status: 200,
                },
            ];
            return prometheusVariants.map((variant) => test(`API: Prometheus metrics (${variant.title})`, async () => {
                const response = await axios.get(`${url}${options.path}`, {
                    auth: variant.auth,
                    maxRedirects: 999,
                    validateStatus: () => true,
                    httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                });
                expect(response.status, 'Response Status').toStrictEqual(variant.status);
            }));
        }
        case 'token': {
            const prometheusVariants = [
                {
                    title: 'no credentials',
                    auth: undefined as unknown as string,
                    status: url.includes('minio') ? 403 : 401,
                },
                {
                    title: 'wrong token',
                    auth: faker.internet.jwt(),
                    status: url.includes('minio') ? 403 : 401,
                },
                {
                    title: 'successful',
                    auth: getEnv(url, 'PROMETHEUS_BEARER_TOKEN'),
                    status: 200,
                },
            ];
            return prometheusVariants.map((variant) => test(`API: Prometheus metrics (${variant.title})`, async () => {
                const headers: Record<string, string> = {};
                if (variant.auth) {
                    headers['Authorization'] = `Bearer ${variant.auth}`;
                }

                const response = await axios.get(`${url}${options.path}`, {
                    headers: headers,
                    maxRedirects: 999,
                    validateStatus: () => true,
                    httpsAgent: new https.Agent({ rejectUnauthorized: false }),
                });
                expect(response.status, 'Response Status').toStrictEqual(variant.status);
            }));
        }
        default: {
            return [];
        }
    };
}
