import fs from 'node:fs';
import fsx from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import express, { type Request, type Response } from 'express';
import dotevn from 'dotenv';
import { execa } from 'execa';
import { PassThrough } from 'node:stream';

if (fs.existsSync('.env')) {
    dotevn.config({ path: '.env', quiet: true });
}
const app = express();

// Healthcheck
app.get('/.health', (_: Request, response: Response) => {
    response.sendStatus(200);
});

// Endpoint for starting a new job
app.post('/run', async (_: Request, response: Response) => {
    try {
        const internalStream = new PassThrough();
        let outputBuffer = '';

        const subprocess = execa('sh', ['/homelab/cron-wrapper.sh'], {
            all: true,
            detached: true,
            env: {
                CRON: '0',
            },
            reject: false,
        });

        subprocess.all?.pipe(internalStream);

        const jobId = await new Promise<string>((resolve, reject) => {
            internalStream.on('data', (chunk) => {
                const text = chunk.toString();
                outputBuffer += text;
                if (outputBuffer.split('\n').some((line) => /^Running job with ID .+$/.test(line))) {
                    const match = outputBuffer.match(/Running job with ID (.+)/)![1];
                    resolve(match);
                }
            });

            internalStream.on('error', reject);
            subprocess.on('error', reject);
        });

        response.status(200);
        response.send({ 'job': jobId });
    } catch (error) {
        console.error('Server error:', error);
        response.status(500);
        response.send({ error: 'Server error' });
    }
});

// Endpoint for reading job logs
app.get('/log/:id', async (request: Request, response: Response) => {
    try {
        const jobId = `${request.params['id']}`;
        const logFilePath = path.join('/', 'homelab', 'logs', jobId, 'output.log');
        if (!fs.existsSync(logFilePath)) {
            response.status(404);
            response.send({ error: 'Logfile not found' });
            return;
        }

        const logContent = await fsx.readFile(logFilePath, 'utf-8');
        response.status(200);
        response.contentType('text/plain');
        response.send(logContent);
    } catch (error) {
        console.error('Server error:', error);
        response.status(500);
        response.send({ error: 'Server error' });
    }
});

app.listen(8080, () => {
    console.log('Server started.');
});

process.on('SIGTERM', () => {
    process.exit(0);
});
