import fs from 'node:fs';
import fsx from 'node:fs/promises';
import path from 'node:path';
import dotevn from 'dotenv';
import express, { type Request, type Response } from 'express';
import mime from 'mime-types';
import { Log } from './log.ts';

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
        let requestedPath: string;
        try {
            requestedPath = decodeURIComponent(request.path);
        } catch {
            response.sendStatus(400);
            return;
        }

        const filepath = path.resolve(root, `.${requestedPath}`);
        const relativePath = path.relative(root, filepath);
        if (relativePath.startsWith('..') || path.isAbsolute(relativePath)) {
            response.sendStatus(403);
            return;
        }
        Log.info(`Request filepath: ${filepath}`);
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
        Log.error('Server error:', error);
        response.sendStatus(500);
    }
});

app.listen(8080, () => {
    Log.info('Server started.');
});

process.on('SIGTERM', () => {
    process.exit(0);
});
