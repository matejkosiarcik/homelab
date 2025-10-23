import fs from 'node:fs';
import https from 'node:https';
import process from 'node:process';
import { default as baseAxios } from 'axios';
import dns from 'native-dns';
import * as tar from 'tar';
import lzma from 'lzma-native';

export async function delay(timeout: number): Promise<void> {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve();
        }, timeout);
    });
}

export async function retry<T>(fn: () => T | Promise<T>, _options?: { retries?: number | undefined; } | undefined): Promise<T> {
    const options = {
        retries: _options?.retries ?? 1,
    };

    let lastError = new Error('Retry placeholder');

    for (let i = 0; i < options.retries; i++) {
        try {
            return await fn();
        } catch (error) {
            lastError = error instanceof Error ? error : new Error(`${error}`);
        }
    }

    throw lastError;
}

export function getEnv(instanceUrl: string, name: string): string {
    const parsedUrl = URL.parse(instanceUrl);
    if (!parsedUrl) {
        throw new Error(`Invalid URL ${instanceUrl}`);
    }
    const instanceName = parsedUrl.hostname.replace(/\.matejhome\.com$/, '').replaceAll('-', '_');
    const envName = `${instanceName}__${name.replaceAll('-', '_')}`.toUpperCase();
    if (!(envName in process.env) || !process.env[envName]) {
        throw new Error(`Environment variable "${envName}" not set`);
    }
    return process.env[envName];
}

export async function dnsLookup(domain: string, transport: 'tcp' | 'udp', type: 'A' | 'AAAA', dnsServer: string): Promise<string[]> {
    return await retry(async () => {
        return await new Promise((resolve, reject) => {
            const returnData: string[] = [];
            const req = dns.Request({
                question: dns.Question({ name: domain, type: type, }),
                server: { address: dnsServer, port: 53, type: transport },
                timeout: 8000,
            });

            req.on('timeout', () => {
                reject(new Error('DNS Timeout'));
            });

            req.on('message', (err: unknown, answer: { answer: { address: string }[] }) => {
                if (err) {
                    reject(new Error(`DNS Message error: ${err}`));
                    return;
                }
                returnData.push(...answer.answer.map((entry) => entry.address));
            });

            req.on('end', () => {
                resolve(returnData.sort());
            });

            req.send();
        });
    }, {
        retries: 2,
    });
}

export const axios = baseAxios.create({
    timeout: 2500,
    httpsAgent: new https.Agent({ rejectUnauthorized: false }),
    maxRedirects: 999,
    validateStatus: () => true,
});

export async function extractTar(file: string, destination: string): Promise<void> {
    await new Promise((resolve, reject) => {
        const stream = fs.createReadStream(file)
            .pipe(lzma.createDecompressor())
            .pipe(
                tar.x({
                    strip: 1,
                    C: destination,
                }),
            );
        stream.on('error', (error) => reject(error));
        stream.on('finish', () => resolve(true));
    });
}
