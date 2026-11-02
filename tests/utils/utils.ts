import fs from 'node:fs';
import https from 'node:https';
import process from 'node:process';
import { default as baseAxios } from 'axios';
import { execa, ExecaError } from 'execa';
import * as tar from 'tar';
import lzma from 'lzma-native';
import { apps } from '#/utils/apps.ts';
import { Locator } from '@playwright/test';

export const validators = {
    network: {
        homelabIp: /^10\.1\.(?:25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.(?:25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$/,
        ipv4: {
            loopback: /^127\.0\.0\.1$/,
            main: /^(?:(?:25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$/,
            private: /^(?:10\.|172\.(?:1[6-9]|2\d|3[0-1])\.|192\.168\.)/,
            zero: /^(?:0\.0\.0\.0)$/,
        },
        ipv6: {
            loopback: /^(?:0:0:0:0:0:0:0:1|::1)$/,
            main: /^(?:(?:[0-9a-f]{1,4}:){7}[0-9a-f]{1,4}|(?:[0-9a-f]{1,4}:){1,7}:|(?:[0-9a-f]{1,4}:){1,6}:[0-9a-f]{1,4}|(?:[0-9a-f]{1,4}:){1,5}(?::[0-9a-f]{1,4}){1,2}|(?:[0-9a-f]{1,4}:){1,4}(?::[0-9a-f]{1,4}){1,3}|(?:[0-9a-f]{1,4}:){1,3}(?::[0-9a-f]{1,4}){1,4}|(?:[0-9a-f]{1,4}:){1,2}(?::[0-9a-f]{1,4}){1,5}|[0-9a-f]{1,4}:(?:(?::[0-9a-f]{1,4}){1,6})|:(?:(?::[0-9a-f]{1,4}){1,7}|:))$/i,
            uniqueLocal: /^f[cd][0-9a-f]{2}:/i, // Equivalent of private IPv4 address ranges
            zero: /^(?:0:0:0:0:0:0:0:0|::)$/,
        },
    },
};

export async function delay(timeout: number): Promise<void> {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve();
        }, timeout);
    });
}

type MaybePromise<T> = T | Promise<T>;

export async function retry<T>(fn: () => MaybePromise<T>, _options?: { retries?: number | undefined; onRetry?: (error: Error, attempt: number) => MaybePromise<void> } | undefined): Promise<T> {
    const options = {
        retries: _options?.retries ?? 1,
        onRetry: _options?.onRetry,
    };

    let lastError = new Error('Retry placeholder');

    for (let i = 0; i < options.retries; i++) {
        try {
            return await fn();
        } catch (error) {
            lastError = error instanceof Error ? error : new Error(`${error}`);
            await options.onRetry?.(lastError, i + 1);
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

export async function dnsLookupWithRetry(domain: string, transport: 'tcp' | 'udp', type: 'A' | 'AAAA', dnsServer: string): Promise<string[]> {
    return await retry(() => dnsLookup(domain, transport, type, dnsServer), { retries: 2 });
}

export async function dnsLookup(domain: string, transport: 'tcp' | 'udp', type: 'A' | 'AAAA', dnsServer: string): Promise<string[]> {
    const timeout = 1000;
    const queryDescription = `DNS query for ${type} record "${domain}" via ${transport.toUpperCase()} to ${dnsServer}`;
    const timeoutError = new Error(`${queryDescription} timed out after ${timeout}ms`);
    const controller = new AbortController();
    let timeoutId: NodeJS.Timeout | undefined;
    const queryPromise = execa('dig', [`@${dnsServer}`, type, '+short', `+${transport === 'udp' ? 'no' : ''}tcp`, domain], { all: true, cancelSignal: controller.signal });
    const timeoutPromise = new Promise<never>((_, reject) => {
        timeoutId = setTimeout(() => {
            reject(timeoutError);
            controller.abort();
        }, timeout);
    });

    try {
        const { stdout } = await Promise.race([queryPromise, timeoutPromise]);
        return stdout.split('\n').filter(Boolean).sort();
    } catch (error) {
        if (error === timeoutError || controller.signal.aborted) {
            throw timeoutError;
        }
        if (error instanceof ExecaError) {
            throw new Error(`${queryDescription} failed: ${`${error.all}`.trim() || error.shortMessage}`);
        }
        throw new Error(`${queryDescription} failed: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
        if (timeoutId) {
            clearTimeout(timeoutId);
        }
    }
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

export function getAllHomelabDomains(): string[] {
    const domains = Object.values(apps)
        .map((app) => app.instances)
        .flat()
        .filter((instance) => ((instance as { enabled?: boolean | undefined }).enabled ?? true) === true)
        .flatMap((instance) => Object.entries(instance))
        .filter(([key, value]) => (key === 'url' || key.toLowerCase().endsWith('url') || key.toLowerCase().startsWith('url')) && typeof value === 'string' && /^https?:\/\/[a-zA-Z0-9_-]+\.matejhome\.com$/.test(value))
        .map(([, value]) => URL.parse(`${value}` as string)?.hostname)
        .filter((hostname): hostname is string => typeof hostname === 'string');
    return [...new Set(domains)];
}

/**
 * Invokes a given promise and errors out if it takes longer than given timeout
 */
export async function withTimeout<T>(operation: () => Promise<T>, timeout: number, message: string): Promise<T> {
    let timeoutId: NodeJS.Timeout | undefined;
    const timeoutPromise = new Promise<never>((_, reject) => {
        timeoutId = setTimeout(() => {
            reject(new Error(message));
        }, timeout);
    });

    try {
        return await Promise.race([operation(), timeoutPromise]);
    } finally {
        if (timeoutId) {
            clearTimeout(timeoutId);
        }
    }
}

/**
 * Waits for instance(s) of locator to be hidden
 * Automatically resolves **all** instances of this locator and waits for all of them to be hidden
 */
export async function waitForHidden(locator: Locator): Promise<void> {
    const set = new Set<string>();
    const timeout = 10_000;

    await withTimeout(async () => {
        while (true) {
            const locators = await locator.all();
            let newLocators = false;

            await Promise.all(locators.map(async (locator) => {
                const locatorDescription = locator.toString();
                if (!set.has(locatorDescription)) {
                    newLocators = true;
                    set.add(locatorDescription);
                }
                await locator.waitFor({ state: 'hidden', timeout: timeout });
            }));

            if (!newLocators) {
                break;
            }
        }
    }, 3 * timeout, `Timed out waiting for ${locator} to be hidden after ${3 * timeout}ms`);
}
