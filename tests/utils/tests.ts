import net from 'node:net';
import { faker } from '@faker-js/faker';
import PromiseSocket from 'promise-socket';
import sharp from 'sharp';
import sharpIco from 'sharp-ico';
import { expect, test } from '#/playwright/test.ts';
import { axios } from '#/utils/axios.ts';
import { getEnv } from '#/utils/utils.ts';

export const sharedMetrics = {
    dockerSockguard: [
        'sockguard_build_info',
        'sockguard_http_request_duration_seconds_bucket',
        'sockguard_http_request_duration_seconds_count',
        'sockguard_http_request_duration_seconds_sum',
        'sockguard_http_requests_active',
        'sockguard_http_requests_total',
        'sockguard_listener_up',
        'sockguard_policy_version',
        'sockguard_start_time_seconds',
    ] as const,
    runWisp: [
        'runwisp_build_info',
        'runwisp_daemon_cpu_percent',
        'runwisp_daemon_memory_total_bytes',
        'runwisp_daemon_memory_used_bytes',
        'runwisp_daemon_uptime_seconds',
        'runwisp_runs_total',
        'runwisp_task_active_runs',
    ] as const,
};

export function createDockerSockguardTests(url: string, invalidUsers: { username: string, passwordEnv: string }[]) {
    for (const user of invalidUsers) {
        test(`API: Docker Sockguard metrics reject user ${user.username}`, async () => {
            const response = await axios.get(`${url}/docker-sockguard/metrics`, {
                auth: {
                    username: user.username,
                    password: getEnv(url, user.passwordEnv),
                },
            });
            expect(response.status, 'Response Status').toStrictEqual(401);
        });
    }

    test(`API: Docker Sockguard metrics reject random user`, async () => {
        const response = await axios.get(`${url}/docker-sockguard/metrics`, {
            auth: {
                username: faker.string.alpha(10),
                password: faker.string.alpha(10),
            },
        });
        expect(response.status, 'Response Status').toStrictEqual(401);
    });

    test('API: Docker Sockguard metrics reject unauthenticated requests', async () => {
        const response = await axios.get(`${url}/docker-sockguard/metrics`);
        expect(response.status, 'Response Status').toStrictEqual(401);
    });

    test('API: Docker Sockguard Prometheus metrics content', async () => {
        const response = await test.step('Request server', async () => {
            const response = await axios.get(`${url}/docker-sockguard/metrics`, {
                auth: {
                    username: 'prometheus',
                    password: getEnv(url, 'DOCKER_SOCKGUARD_PROMETHEUS_PASSWORD'),
                },
                timeout: 15_000,
            });
            expect(response.status, 'Response Status').toStrictEqual(200);
            return response;
        });

        await test.step('Validate response', async () => {
            const content = response.data as string;
            await test.info().attach('docker-sockguard-metrics.txt', { contentType: 'text/plain', body: content });
            const lines = content.split('\n');
            for (const metric of sharedMetrics.dockerSockguard) {
                expect.soft(lines.find((line) => new RegExp(`^${metric}(?:[{ ]|$)`).test(line)), `Metric ${metric} should be present`).toBeDefined();
            }
        });
    });
}

export function createTcpTests(url: string, _ports: number | number[], _options?: { title?: string | undefined } | undefined) {
    const options = {
        title: _options?.title ?? '',
    };
    const ports = [_ports].flat();
    return ports.map((port) => test(`TCP: Connect to port ${port}${options.title ? ` ${options.title}` : ''}`, async () => {
        const host = url.replace(/^.*?:\/\//, '');
        const socket = new net.Socket();
        const promiseSocket = new PromiseSocket(socket);
        await promiseSocket.connect(port, host);
        await promiseSocket.end();
    }));
}

export function createApiRootTest(url: string, _options?: { headers?: Record<string, string> | undefined, title?: string | undefined, status?: number | undefined } | undefined) {
    const options = {
        headers: _options?.headers ?? {},
        title: _options?.title ?? '',
        status: _options?.status ?? 200,
    };
    return [
        test(`API: Get root${options.title ? ` - ${options.title}` : ''}`, async () => {
            const response = await test.step('Request server', async () => {
                const response = await axios.get(url, { headers: options.headers });
                expect(response.status, 'Response Status').toStrictEqual(options.status);
                return response;
            });

            await test.step('Validate response', async () => {
                if (options.title !== 'portal') {
                    expect(response.headers['Server'] || response.headers['server'], 'Response Proxy Server header').toStrictEqual('Apache');
                }
            });
        }),
    ];
}

export function createHttpToHttpsRedirectTests(url: string, _options?: { title?: string | undefined } | undefined) {
    const options = {
        title: _options?.title ?? '',
    };
    const port = url.match(/:(\d+)$/)?.[0] ?? '';
    const urlWithTrailingSlash = new URL(url).pathname === '/' || url.endsWith('/') ? url : `${url}/`;
    return [
        test(`API: Redirect HTTP${port} to HTTPS (root)${options.title ? ` - ${options.title}` : ''}`, async () => {
            const response = await test.step('Request server', async () => {
                const response = await axios.get(url.replace('https://', 'http://'), { maxRedirects: 0 });
                expect(response.status, 'Response Status').toStrictEqual(302);
                return response;
            });

            await test.step('Validate response', async () => {
                expect(response.headers['location'], 'Response header location').toStrictEqual(url.replace('http://', 'https://').replace(/:\d+$/, ''));
            });
        }),

        test(`API: Redirect HTTP${port} to HTTPS (root slash)${options.title ? ` - ${options.title}` : ''}`, async () => {
            const response = await test.step('Request server', async () => {
                const response = await axios.get(`${url.replace('https://', 'http://')}/`, { maxRedirects: 0 });
                expect(response.status, 'Response Status').toStrictEqual(302);
                return response;
            });

            await test.step('Validate response', async () => {
                expect(response.headers['location'], 'Response header location').toStrictEqual(urlWithTrailingSlash.replace('http://', 'https://').replace(/:\d+$/, ''));
            });
        }),

        test(`API: Redirect HTTP${port} to HTTPS (random subpage)${options.title ? ` - ${options.title}` : ''}`, async () => {
            const subpage = `/${faker.string.alpha(10)}`;
            const response = await test.step('Request server', async () => {
                const response = await axios.get(`${url.replace('https://', 'http://')}${subpage}`, { maxRedirects: 0 });
                expect(response.status, 'Response Status').toStrictEqual(302);
                return response;
            });

            await test.step('Validate response', async () => {
                expect(response.headers['location'], 'Response header location').toStrictEqual(`${url.replace('http://', 'https://').replace(/:\d+$/, '')}${subpage}`);
            });
        }),
    ];
}

export function createHttpsRootRedirectTest(url: string, targetPath: string) {
    return test(`API: HTTPS redirect root to ${targetPath}`, async () => {
        const response = await test.step('Request server', async () => {
            const response = await axios.get(url, { maxRedirects: 0 });
            expect(response.status, 'Response Status').toStrictEqual(302);
            return response;
        });

        await test.step('Validate response', async () => {
            expect(response.headers['location'], 'Response Header Location').toStrictEqual(`${url}${targetPath}`);
        });
    });
}

export function createHttpsToHttpRedirectTests(url: string) {
    return [
        test('API: Redirect HTTPS to HTTP (root)', async () => {
            const response = await test.step('Request server', async () => {
                const response = await axios.get(url.replace('http://', 'https://'), { maxRedirects: 0 });
                expect(response.status, 'Response Status').toStrictEqual(302);
                return response;
            });

            await test.step('Validate response', async () => {
                expect(response.headers['location'], 'Response header location').toStrictEqual(url.replace('https://', 'http://'));
            });
        }),

        test('API: Redirect HTTPS to HTTP (root slash)', async () => {
            const response = await test.step('Request server', async () => {
                const response = await axios.get(`${url.replace('http://', 'https://')}/`, { maxRedirects: 0 });
                expect(response.status, 'Response Status').toStrictEqual(302);
                return response;
            });

            await test.step('Validate response', async () => {
                expect(response.headers['location'], 'Response header location').toStrictEqual(url.replace('https://', 'http://'));
            });
        }),

        test('API: Redirect HTTPS to HTTP (random subpage)', async () => {
            const subpage = `/${faker.string.alpha(10)}`;
            const response = await test.step('Request server', async () => {
                const response = await axios.get(`${url.replace('http://', 'https://')}${subpage}`, { maxRedirects: 0 });
                expect(response.status, 'Response Status').toStrictEqual(302);
                return response;
            });

            await test.step('Validate response', async () => {
                expect(response.headers['location'], 'Response header location').toStrictEqual(`${url.replace('https://', 'http://')}${subpage}`);
            });
        }),
    ];
}

export function createFaviconTests(url: string, _options?: { headers?: Record<string, string> | undefined, title?: string | undefined } | undefined) {
    const options = {
        headers: _options?.headers ?? {},
        title: _options?.title ?? '',
    };
    return [
        test(`API: Get favicon.ico${options.title ? ` - ${options.title}` : ''}`, async () => {
            const response = await test.step('Request server', async () => {
                const response = await axios.get(`${url}/favicon.ico`, {
                    headers: options.headers,
                    responseType: 'arraybuffer',
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
                return response;
            });

            await test.step('Validate response', async () => {
                const sharpIcons = sharpIco.sharpsFromIco(response.data);
                expect(sharpIcons.length, `Favicon.ico should have some decoded images`).toBeGreaterThanOrEqual(1);
                for (const el of sharpIcons.entries()) {
                    const faviconBuffer = await (async () => {
                        if ('data' in el[1]) {
                            return await sharp(el[1].data).toFormat('raw').toBuffer();
                        }
                        return el[1].toFormat('raw').toBuffer();
                    })();
                    expect(faviconBuffer.length, `Favicon.ico image ${el[0]} decoded size should be nonzero`).toBeGreaterThan(1);
                }
            });
        }),
        test(`API: Get favicon.png${options.title ? ` - ${options.title}` : ''}`, async () => {
            const response = await test.step('Request server', async () => {
                const response = await axios.get(`${url}/favicon.png`, {
                    headers: options.headers,
                    responseType: 'arraybuffer',
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
                return response;
            });

            await test.step('Validate response', async () => {
                const faviconBuffer = await sharp(response.data).toFormat('raw').toBuffer();
                expect(faviconBuffer.length, 'Favicon.png decoded size should be nonzero').toBeGreaterThan(1);
            });
        }),
    ];
}

export function createProxyTests(url: string, _options?: { redirect?: boolean | undefined; title?: string | undefined } | undefined) {
    const options = {
        redirect: _options?.redirect ?? true,
        title: _options?.title ?? '',
    };

    const output = [
        test(`API: Proxy root${options.title ? ` - ${options.title}` : ''}`, async () => {
            await test.step('Request server', async () => {
                const response = await axios.get(`${url}/.apache`);
                expect(response.status, 'Response Status').toStrictEqual(200);
            });
        }),
    ];

    if (options.redirect) {
        output.push(
            test(`API: Proxy redirect to HTTPS${options.title ? ` - ${options.title}` : ''}`, async () => {
                const response = await test.step('Request server', async () => {
                    const response = await axios.get(`${url.replace('https://', 'http://')}/.apache`, { maxRedirects: 0 });
                    expect(response.status, 'Response Status').toStrictEqual(302);
                    return response;
                });

                await test.step('Validate response', async () => {
                    expect(response.headers['location'], 'Response header location').toStrictEqual(`${url.replace('http://', 'https://')}/.apache`);
                });
            }),
        );
    }

    const proxyStatusVariants = [
        {
            title: 'no credentials',
            auth: undefined as unknown as { username: string, password: string },
            status: 401,
        },
        {
            title: 'empty password',
            auth: {
                username: 'status',
                password: '',
            },
            status: 401,
        },
        {
            title: 'wrong password',
            auth: {
                username: 'status',
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
            title: 'old username',
            auth: {
                username: 'proxy-status',
                password: getEnv(url, 'PROXY_STATUS_PASSWORD'),
            },
            status: 401,
        },
        {
            title: 'successful',
            auth: {
                username: 'status',
                password: getEnv(url, 'PROXY_STATUS_PASSWORD'),
            },
            status: 200,
        },
    ];
    output.push(...proxyStatusVariants.map((variant) => {
        return test(`API: Proxy status (${variant.title})${options.title ? ` - ${options.title}` : ''}`, async () => {
            await test.step('Request server', async () => {
                const response = await axios.get(`${url}/.apache/status`, { auth: variant.auth });
                expect(response.status, 'Response Status').toStrictEqual(variant.status);
            });
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
                username: 'prometheus',
                password: '',
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
            title: 'wrong username/password',
            auth: {
                username: faker.string.alphanumeric(10),
                password: faker.string.alphanumeric(10),
            },
            status: 401,
        },
        {
            title: 'old username',
            auth: {
                username: 'proxy-prometheus',
                password: getEnv(url, 'PROXY_PROMETHEUS_PASSWORD'),
            },
            status: 401,
        },
        {
            title: 'successful',
            auth: {
                username: 'prometheus',
                password: getEnv(url, 'PROXY_PROMETHEUS_PASSWORD'),
            },
            status: 200,
        },
    ];
    output.push(...proxyPrometheusVariants.map((variant) => {
        return test(`API: Proxy prometheus metrics (${variant.title})${options.title ? ` - ${options.title}` : ''}`, async () => {
            await test.step('Request server', async () => {
                const response = await axios.get(`${url}/.apache/metrics`, { auth: variant.auth });
                expect(response.status, 'Response Status').toStrictEqual(variant.status);
            });
        });
    }));

    output.push(
        test(`API: Proxy prometheus metrics content${options.title ? ` - ${options.title}` : ''}`, async () => {
            const response = await test.step('Request server', async () => {
                const response = await axios.get(`${url}/.apache/metrics`, {
                    auth: {
                        username: 'prometheus',
                        password: getEnv(url, 'PROXY_PROMETHEUS_PASSWORD'),
                    },
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
                return response;
            });

            await test.step('Validate response', async () => {
                const content = response.data as string;
                await test.info().attach('metrics.txt', { contentType: 'text/plain', body: content });
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
            });
        }),
    );

    return output;
}

export function createPrometheusTests(url: string, _options: { auth?: 'none' | 'basic' | 'bearer' | undefined; path?: string | string[] | undefined; username?: string | undefined; token?: string | string[] } = {}) {
    const options = {
        auth: _options.auth ?? 'basic',
        path: _options.path ? [_options.path].flat() : ['/metrics'],
        username: _options.username ?? 'prometheus',
        passwordsOrTokens: _options.token ? [_options.token].flat() : [],
    };

    switch (options.auth) {
        case 'basic': {
            if (options.passwordsOrTokens.length === 0) {
                options.passwordsOrTokens.push(getEnv(url, `${options.username}_PASSWORD`));
            }
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
                        username: options.username,
                        password: faker.string.alphanumeric(10),
                    },
                    status: 401,
                },
                ...options.passwordsOrTokens.map((password, index) => ({
                    title: options.passwordsOrTokens.length === 1 ? 'successful' : `successful ${index + 1}`,
                    auth: {
                        username: options.username,
                        password: password,
                    },
                    status: 200,
                })),
            ];
            return options.path.flatMap((path, index) => {
                return prometheusVariants.map((variant) => test(`API: Prometheus metrics with Basic auth (${variant.title})${options.path.length > 1 ? ` path-${index + 1}` : ''}`, async () => {
                    await test.step('Request server', async () => {
                        const response = await axios.get(`${url}${path}`, { auth: variant.auth, timeout: 10_000 });
                        expect(response.status, 'Response Status').toStrictEqual(variant.status);
                    });
                }));
            });
        }
        case 'bearer': {
            if (options.passwordsOrTokens.length === 0) {
                options.passwordsOrTokens.push(getEnv(url, 'PROMETHEUS_BEARER_TOKEN'));
            }
            const prometheusVariants = [
                {
                    title: 'no credentials',
                    auth: undefined as unknown as string,
                    status: url.includes('minio') ? 403 : 401,
                },
                {
                    title: 'wrong token',
                    auth: faker.internet.jwt(),
                    status: url.includes('minio') ? 403 : url.includes('healthchecks') ? 400 : 401,
                },
                ...options.passwordsOrTokens.map((token, index) => ({
                    title: options.passwordsOrTokens.length === 1 ? 'successful' : `successful ${index + 1}`,
                    auth: token,
                    status: 200,
                })),
            ];
            return options.path.flatMap((path, index) => {
                return prometheusVariants.map((variant) => test(`API: Prometheus metrics with Bearer auth (${variant.title})${options.path.length > 1 ? ` path-${index + 1}` : ''}`, async () => {
                    const headers: Record<string, string> = {};
                    if (variant.auth) {
                        headers['Authorization'] = `Bearer ${variant.auth}`;
                    }

                    await test.step('Request server', async () => {
                        const response = await axios.get(`${url}${path}`, { headers: headers });
                        expect(response.status, 'Response Status').toStrictEqual(variant.status);
                    });
                }));
            });
        }
        case 'none': {
            const prometheusVariants = [
                {
                    title: 'successful',
                    path: options.path,
                    status: 200,
                },
                // {
                //     title: 'unsuccessful 1',
                //     path: `${options.path.slice(0, -1)}`,
                //     status: 403,
                // },
                // {
                //     title: 'unsuccessful 2',
                //     path: `${options.path}${faker.string.alpha(4)}`,
                //     status: 403,
                // },
            ];
            return options.path.flatMap((path, index) => {
                return prometheusVariants.map((variant) => test(`API: Prometheus metrics with No auth (${variant.title})${options.path.length > 1 ? ` path-${index + 1}` : ''}`, async () => {
                    await test.step('Request server', async () => {
                        const response = await axios.get(`${url}${path}`);
                        expect(response.status, 'Response Status').toStrictEqual(variant.status);
                    });
                }));
            });
        }
        default: {
            return [];
        }
    };
}
