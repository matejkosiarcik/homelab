import fs from 'node:fs';
import express, { Request, Response } from 'express';
import dotevn from 'dotenv';

if (fs.existsSync('.env')) {
    dotevn.config({ path: '.env', quiet: true });
}

const app = express();
app.use(express.json())

// Healthcheck
app.get('/.health', (_: Request, response: Response) => {
    response.sendStatus(200);
});

type Payload = {
    _type: 'encrypted',
    data: string,
};

app.post('/pub', async (request: Request, response: Response) => {
    try {
        const data = request.body as Payload;
        console.log('Data:', data)
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
