import fs from 'node:fs';
import express, { Request, Response } from 'express';
import axios from 'axios';
import dotevn from 'dotenv';

if (fs.existsSync('.env')) {
    dotevn.config({ path: '.env', quiet: true });
}
if (!process.env['PROMETHEUS_PASSWORD']) {
    console.error('PROMETHEUS_PASSWORD unset!');
    process.exit(1);
}
const authorizationHeader = 'Basic ' + Buffer.from(`admin:${process.env['PROMETHEUS_PASSWORD']}`).toString('base64');

const app = express();

// Healthcheck
app.get('/.widget-prometheus/health', (_: Request, response: Response) => {
    response.sendStatus(200);
});

// Interception middleware
app.use(async (request: Request, response: Response) => {
    try {
        const targetUrl = `https://prometheus.home.matejkosiarcik.com${request.path}`;
        const axiosHeaders = {
            ...request.headers,
            authorization: authorizationHeader
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
        console.error('Proxy error:', error);
        response.sendStatus(500);
    }
});

app.listen(8080, () => {
    console.log('Server started.');
});
