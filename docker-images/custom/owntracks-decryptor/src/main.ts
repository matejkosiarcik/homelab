import fs from 'node:fs';
import express, { Request, Response } from 'express';
import dotevn from 'dotenv';

if (fs.existsSync('.env')) {
    dotevn.config({ path: '.env', quiet: true });
}

const app = express();

// Healthcheck
app.get('/.health', (_: Request, response: Response) => {
    response.sendStatus(200);
});

app.post('/pub', async (request: Request, response: Response) => {
    try {
        console.log('Received:', request.body);
        response.status(200);
        response.send({});
    } catch (error) {
        console.error('Favicon error:', error);
        response.sendStatus(500);
    }
});

app.listen(8080, () => {
    console.log('Server started.');
});
