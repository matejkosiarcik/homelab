import fs from 'node:fs';
import dotevn from 'dotenv';
import express, { type Request, type Response } from 'express';

if (fs.existsSync('.env')) {
    dotevn.config({ path: '.env', quiet: true });
}

let started = false;

const app = express();

app.use(express.static('./icons'));
app.use(express.static('./www'));

// Healthcheck
app.get('/.health', (_: Request, response: Response) => {
    response.sendStatus(started ? 200 : 503);
});

app.get('/', async (_: Request, response: Response) => {
    response.sendStatus(200);
});

app.listen(8080, () => {
    console.log('Server started.');
});

// Init server
(async () => {
    // TODO: Initialize database
    started = true;
})();

process.on('SIGTERM', () => {
    process.exit(0);
});
