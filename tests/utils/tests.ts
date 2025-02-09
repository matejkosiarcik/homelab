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

export function createHttpToHttpsRedirectTests(url: string) {
    return [
        test('API: Redirect HTTP to HTTPS (root)', async () => {
            const response = await axios.get(url.replace(/^https:\/\//, 'http://'), { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, validateStatus: () => true });
            expect(response.status, 'Response Status').toStrictEqual(302);
            expect(response.headers['location'], 'Response header location').toStrictEqual(url);
        }),

        test('API: Redirect HTTP to HTTPS (root slash)', async () => {
            const response = await axios.get(`${url.replace(/^https:\/\//, 'http://')}/`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, validateStatus: () => true });
            expect(response.status, 'Response Status').toStrictEqual(302);
            expect(response.headers['location'], 'Response header location').toStrictEqual(url);
        }),

        test('API: Redirect HTTP to HTTPS (random subpage)', async () => {
            const subpage = `/${faker.string.alpha(10)}`;
            const response = await axios.get(`${url.replace(/^https:\/\//, 'http://')}${subpage}`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, validateStatus: () => true });
            expect(response.status, 'Response Status').toStrictEqual(302);
            expect(response.headers['location'], 'Response header location').toStrictEqual(`${url}${subpage}`);
        }),
    ];
}

export function createProxyStatusTests(url: string) {
    const proxyStatusVariants = [
        {
            title: 'missing credentials',
            auth: undefined as unknown as { username: string, password: string },
            status: 401,
        },
        {
            title: 'wrong credentials',
            auth: {
                username: 'proxy-status',
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
    return proxyStatusVariants.map((variant) => {
        return test(`API: Proxy status (${variant.title})`, async () => {
            const response = await axios.get(`${url}/.proxy/status`, {
                auth: variant.auth,
                maxRedirects: 999,
                validateStatus: () => true,
                httpsAgent: new https.Agent({ rejectUnauthorized: false }),
            });
            expect(response.status, 'Response Status').toStrictEqual(variant.status);
        });
    });
}
