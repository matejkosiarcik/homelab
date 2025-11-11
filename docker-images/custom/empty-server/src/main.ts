import fs from 'node:fs';
import dotevn from 'dotenv';
import express, { type Request, type Response } from 'express';

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

app.listen(8080, () => {
    console.log('Server started.');
});

process.on('SIGTERM', () => {
    process.exit(0);
});
