import net from 'node:net';
import PromiseSocket from 'promise-socket';
import { test } from '@playwright/test';

export function createTcpTest(url: string, port: number) {
    return test(`TCP: Connect to port ${port}`, async () => {
        const host = url.replace(/^.*?:\/\//, '');
        const socket = new net.Socket();
        const promiseSocket = new PromiseSocket(socket);
        await promiseSocket.connect(port, host);
        await promiseSocket.end();
    });
}
