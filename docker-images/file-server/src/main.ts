import fs from 'node:fs';
import fsx from 'node:fs/promises';
import path from 'node:path';
import dotevn from 'dotenv';
import express, { type Request, type Response } from 'express';
import mime from 'mime-types';

if (fs.existsSync('.env')) {
    dotevn.config({ path: '.env', quiet: true });
}

const app = express();

// Root
app.get('/', (_: Request, response: Response) => {
    response.sendStatus(200);
});

// Healthcheck
app.get('/.health', (_: Request, response: Response) => {
    response.sendStatus(200);
});

app.use(async (request: Request, response: Response) => {
    try {
        if (!['GET', 'HEAD', 'OPTIONS'].includes(request.method)) {
            response.sendStatus(404);
            return;
        }

        const root = path.join('/', 'homelab', 'www');
        const filepath = path.join(root, ...request.path.split(/\//));
        console.log(`Request filepath: ${filepath}`);
        if (!fs.existsSync(filepath)) {
            response.sendStatus(404);
            return;
        }

        const stats = await fsx.stat(filepath);
        if (!stats.isFile()) {
            response.sendStatus(404);
            return;
        }

        const extension = path.extname(filepath);
        const contentType = mime.lookup(extension) || 'application/octet-stream';

        response.status(200);
        response.setHeader('Content-Type', contentType);
        if (request.method === 'GET') {
            const content = await fsx.readFile(filepath);
            response.send(content);
        } else {
            response.send();
        }
    } catch (error) {
        console.error('Server error:', error);
        response.sendStatus(500);
    }
});

app.listen(8080, () => {
    console.log('Server started.');
});

process.on('SIGTERM', () => {
    process.exit(0);
});
