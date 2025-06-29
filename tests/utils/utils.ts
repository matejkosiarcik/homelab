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
    })
}

export function getEnv(instanceUrl: string, name: string): string {
    const instanceName = URL.parse(instanceUrl)!.hostname.replace(/\.matejhome\.com$/, '').replaceAll('-', '_');
    const envName = `${instanceName}_${name}`.toUpperCase();
    if (!(envName in process.env) || !process.env[envName]) {
        throw new Error(`Environment variable "${envName}" not set`);
    }
    return process.env[envName];
}

export async function dnsLookup(domain: string, transport: 'tcp' | 'udp', type: 'A' | 'AAAA', dnsServer: string): Promise<string[]> {
    return new Promise((resolve, reject) => {
        const returnData: string[] = [];
        const req = dns.Request({
            question: dns.Question({ name: domain, type: type, }),
            server: { address: dnsServer, port: 53, type: transport },
            timeout: 2000,
        });

        req.on('timeout', () => {
            reject(new Error('DNS Timeout'));
        });

        req.on('message', function (err: any, answer: { answer: { address: string }[] }) {
            if (err) {
                reject(new Error(`DNS Message error: ${err}`));
                return;
            }
            returnData.push(...answer.answer.map((entry) => entry.address));
        });

        req.on('end', function () {
            resolve(returnData.sort());
        });

        req.send();
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
