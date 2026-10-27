import fs from 'node:fs';
import dotevn from 'dotenv';
import express, { type Request, type Response } from 'express';
import { Log } from './log.ts';

if (fs.existsSync('.env')) {
    dotevn.config({ path: '.env', quiet: true });
}

const filesRootDirectory = '/homelab/www';

const app = express();

// Root
app.get('/', (_: Request, response: Response) => {
    response.sendStatus(200);
});

// Healthcheck
app.get('/.health', (_: Request, response: Response) => {
    response.sendStatus(200);
});

// Serve files
app.use(express.static(filesRootDirectory, {
    dotfiles: 'deny',
    fallthrough: false,
    index: false,
    redirect: false,
}));

app.listen(8080, () => {
    Log.info('Server started.');
});

process.on('SIGTERM', () => {
    process.exit(0);
});
