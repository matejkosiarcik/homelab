import fs from 'node:fs';
import axios from 'axios';
import dotevn from 'dotenv';
import express, { Request, Response } from 'express';
import sodium from 'libsodium-wrappers';

if (fs.existsSync('.env')) {
    dotevn.config({ path: '.env', quiet: true });
}

const keyEnv = process.env['SECRET_KEY']!;
if (!keyEnv) {
    throw new Error('SECRET_KEY unset');
}

const app = express();
app.use(express.json())

// Healthcheck
app.get('/.health', (_: Request, response: Response) => {
    response.sendStatus(200);
});

type EncryptedPayload = {
    _type: 'encrypted',
    data: string,
};

async function decryptPayload(input: string): Promise<string> {
    await sodium.ready;
    const unsanitizedText = input.replaceAll('\\/', '\\');
    const nonce = Uint8Array.from(Buffer.from(unsanitizedText, 'base64')).slice(0, sodium.crypto_secretbox_NONCEBYTES);
    const cipher = Uint8Array.from(Buffer.from(unsanitizedText, 'base64')).slice(sodium.crypto_secretbox_NONCEBYTES);

    // Private key - padded to 32 bytes
    const keyRawBuffer = Buffer.from(keyEnv, 'ascii');
    const key = Buffer.alloc(32);
    keyRawBuffer.copy(key, 0, 0, Math.min(keyRawBuffer.length, 32));

    const decryptedText = sodium.crypto_secretbox_open_easy(
        cipher,
        nonce,
        key,
        'base64'
    );

    return Buffer.from(decryptedText, 'base64').toString('utf8');
}

app.post('/pub', async (request: Request, response: Response) => {
    try {
        const body = request.body as EncryptedPayload;
        if (body._type !== 'encrypted') {
            throw new Error(`Unknown request type: ${body._type}`);
        }

        const headers: Record<string, string> = {};
        for (const [key, value] of Object.entries(request.headers)) {
            if (typeof value !== 'string') {
                continue
            }
            if (key.toLowerCase().startsWith('x-') || key.toLowerCase() === 'user-agent') {
                headers[key] = `${value}`;
            }
        }

        const decryptedText = await decryptPayload(body.data);
        const decryptedData = JSON.parse(decryptedText);
        const axiosResponse = await axios.post(`http://app-backend:8083${request.url.replace(/^https?:\/\/.+?\//, '')}`, decryptedData, { headers: headers });

        console.log(`${new Date().toISOString()} Forwarding value: ${JSON.stringify(decryptedData)}`);

        response.status(axiosResponse.status);
        response.send(axiosResponse.data);
    } catch (error) {
        console.error('Server error:', error);
        response.sendStatus(500);
    }
});

app.listen(8080, () => {
    console.log('Server started.');
});
