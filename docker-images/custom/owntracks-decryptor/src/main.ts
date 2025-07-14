import fs from 'node:fs';
import express, { Request, Response } from 'express';
import dotevn from 'dotenv';
import sodium from 'libsodium-wrappers';
import axios from 'axios';

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

async function decryptPayload(input: string): Promise<string> {
    await sodium.ready;
    console.log('Nonce length:', sodium.crypto_secretbox_NONCEBYTES);
    const unsanitizedText = input.replaceAll('\\/', '\\');
    console.log('Unsanitized text:', unsanitizedText);
    console.log('Text decoded:', Buffer.from(unsanitizedText, 'base64').length);
    // const decodedText = sodium.from_base64(unsanitizedText);
    const nonce = Buffer.from(unsanitizedText.slice(0, sodium.crypto_secretbox_NONCEBYTES), 'base64');
    const cipher = Buffer.from(unsanitizedText.slice(sodium.crypto_secretbox_NONCEBYTES), 'base64');

    const decryptedText = sodium.crypto_secretbox_open_easy(
        cipher,
        nonce,
        Buffer.from('password', 'utf8'),
    );

    return Buffer.from(decryptedText).toString('utf8');
}

app.post('/pub', async (request: Request, response: Response) => {
    try {
        const body = request.body as Payload;
        if (body._type !== 'encrypted') {
            throw new Error(`Unknown request type: ${body._type}`);
        }

        console.log('Data:', body)
        const decryptedData = await decryptPayload(body.data);
        console.log('Decrypted:', decryptedData);

        const newPayload = {
            _type: 'encrypted',
            data: decryptedData,
        };

        const url = `http://app-backend:8083${request.path}?${request.query}`;
        console.log('URL:', url);
        await axios.post(url, newPayload);

        response.status(200);
        response.send({});
    } catch (error) {
        console.error('Server error:', error);
        response.sendStatus(500);
    }
});

app.listen(8080, () => {
    console.log('Server started.');
});
