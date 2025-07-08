import fs from 'node:fs';
import express, { Request, Response } from 'express';
import axios from 'axios';
import dotevn from 'dotenv';

if (fs.existsSync('.env')) {
    dotevn.config({ path: '.env', quiet: true });
}

const appType = (() => {
    if (!process.env['HOMELAB_APP_TYPE']) {
        console.error('HOMELAB_APP_TYPE is unset');
        process.exit(1);
    }
    return process.env['HOMELAB_APP_TYPE'];
})();
const appAddress = (() => {
    switch (appType) {
        case 'gatus': {
            return 'http://app:8080';
        }
        default: {
            throw new Error(`Unknown app type ${appType}`);
        }
    }
})();
const app = express();

// Healthcheck
app.get('/.health', (_: Request, response: Response) => {
    response.sendStatus(200);
});

app.get('/favicon.ico', async (_: Request, response: Response) => {
    try {
        // const defaultSizes = [48, 32, 16];
        const path = (() => {
            switch (appType) {
                case 'gatus': {
                    return '/favicon.ico';
                }
                default: {
                    return '';
                }
            }
        })();
        const favicon = await downloadFavicon(path);
        const processedFavicon = (() => {
            switch (appType) {
                default: {
                    return favicon;
                }
            }
        })();

        response.status(200);
        response.setHeader('Content-Type', 'image/x-icon');
        response.send(processedFavicon);
    } catch (error) {
        console.error('Favicon error:', error);
        response.sendStatus(500);
    }
});

app.get('/favicon.png', async (_: Request, response: Response) => {
    try {
        // const defaultSize = 64;
        const path = (() => {
            switch (appType) {
                case 'gatus': {
                    return '/favicon-32x32.png';
                }
                default: {
                    return '';
                }
            }
        })();
        const favicon = await downloadFavicon(path);
        const processedFavicon = (() => {
            switch (appType) {
                default: {
                    return favicon;
                }
            }
        })();

        response.status(200);
        response.setHeader('Content-Type', 'image/png');
        response.send(processedFavicon);
    } catch (error) {
        console.error('Favicon error:', error);
        response.sendStatus(500);
    }
});

async function downloadFavicon(path: string): Promise<ArrayBuffer> {
    const headers: Record<string, string> = {};
    switch (appType) {
        case 'smtp4dev': {
            headers['Authorization'] = `Basic ${Buffer.from(`admin:${process.env['SMTP4DEV_PASSWORD']}`).toString('base64')}`;
            break;
        }
        default: {
            break;
        }
    }
    const axiosResponse = await axios.get(`${appAddress}${path}`, {
        headers: headers,
        maxRedirects: 99,
        responseType: 'arraybuffer',
        timeout: 1000,
        validateStatus: () => true,
    });

    if (axiosResponse.status === 0) {
        throw new Error('Upstream error, no response.');
    }
    if (axiosResponse.status !== 200) {
        throw new Error(`Upstream error ${axiosResponse.status}.`);
    }

    return axiosResponse.data;
}

app.listen(8080, () => {
    console.log('Server started.');
});
