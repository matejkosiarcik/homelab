import net from 'node:net';
import PromiseSocket from 'promise-socket';
import https from 'node:https';
import axios from 'axios';
import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';

export function createTcpTest(url: string, port: number, subtitle?: string | undefined) {
    return test(`TCP: Connect to port ${port}${subtitle ? ` ${subtitle}` : ''}`, async () => {
        const host = url.replace(/^.*?:\/\//, '');
    const socket = new net.Socket();
        const promiseSocket = new PromiseSocket(socket);
        await promiseSocket.connect(port, host);
        await promiseSocket.end();
    });
}

export function createHttpsRedirectTest(url: string) {
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
