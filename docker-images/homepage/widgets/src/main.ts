import fs from 'node:fs';
import express, { type Request, type Response } from 'express';
import axios from 'axios';
import dotevn from 'dotenv';
import { Log } from './log.ts';

if (fs.existsSync('.env')) {
    dotevn.config({ path: '.env', quiet: true });
}

for (const envName of ['PROMETHEUS_PASSWORD', 'SMTP4DEV_PASSWORD']) {
    if (!process.env[envName]) {
        Log.error(`Env ${envName} unset!`);
        process.exit(1);
    }
}

const app = express();

// Healthcheck
app.get('/.health', (_: Request, response: Response) => {
    response.sendStatus(200);
});

// Smtp4dev
type Smtp4devResponse = {
    results: [
        {
            isRelayed: boolean,
            deliveredTo: string,
            id: string,
            from: string,
            to: string[],
            receivedDate: string,
            subject: string,
            attachmentCount: number,
            isUnread: boolean,
        },
    ],
    currentPage: number,
    pageCount: number,
    pageSize: number,
    rowCount: number,
    firstRowOnPage: number,
    lastRowOnPage: number,
};

app.get('/smtp4dev', async (_: Request, response: Response) => {
    try {
        const axiosResponse = await axios.get('https://smtp4dev.matejhome.com/api/messages?page=1&pageSize=100', {
            headers: {
                authorization: `Basic ${Buffer.from(`homelab-viewer:${process.env['SMTP4DEV_PASSWORD']}`).toString('base64')}`,
            },
            maxRedirects: 99,
        });

        const total = (axiosResponse.data as Smtp4devResponse).results.length;
        const unread = (axiosResponse.data as Smtp4devResponse).results.filter((el) => el.isUnread === true).length;

        response.status(200);
        response.send({ total: total, unread: unread });
    } catch (error) {
        Log.error('Proxy error:', error);
        response.sendStatus(500);
    }
});

// Prometheus
app.use('/prometheus', async (request: Request, response: Response) => {
    try {
        const targetUrl = `https://prometheus.matejhome.com${request.path}`;
        const axiosHeaders = {
            ...request.headers,
            authorization: `Basic ${Buffer.from(`homelab-viewer:${process.env['PROMETHEUS_PASSWORD']}`).toString('base64')}`,
        };
        delete axiosHeaders['host'];

        const axiosResponse = await axios.request({
            url: targetUrl,
            method: request.method,
            headers: axiosHeaders,
            data: request.body,
            responseType: 'stream',
            validateStatus: () => true,
            maxRedirects: 0,
        });

        response.status(axiosResponse.status);
        for (const [key, value] of Object.entries(axiosResponse.headers)) {
            response.header(key, value);
        }
        axiosResponse.data.pipe(response);
    } catch (error) {
        Log.error('Proxy error:', error);
        response.sendStatus(500);
    }
});

app.listen(8080, () => {
    Log.info('Server started.');
});

process.on('SIGTERM', () => {
    process.exit(0);
});
