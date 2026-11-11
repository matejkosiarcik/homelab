import fs from 'node:fs';
import fsx from 'node:fs/promises';
import net from 'node:net';
import os from 'node:os';
import process from 'node:process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Locator } from '@playwright/test';
import { execa, ExecaError } from 'execa';
import _ from 'lodash';
import lzma from 'lzma-native';
import pParallel from 'p-parallel';
import * as tar from 'tar';

const repositoryPath = fileURLToPath(new URL('../..', import.meta.url));

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

export async function dnsLookupWithRetry(domain: string, transport: 'tcp' | 'udp', type: 'A' | 'AAAA' | 'CNAME', dnsServer: string): Promise<string[]> {
    return await retry(() => dnsLookup(domain, transport, type, dnsServer), { retries: 2 });
}

export async function dnsLookup(domain: string, transport: 'tcp' | 'udp', type: 'A' | 'AAAA' | 'CNAME', dnsServer: string): Promise<string[]> {
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

export type HomelabDomain = {
    name: string;
    ips: {
        type: 'A' | 'AAAA' | 'CNAME',
        ip: string,
    }[],
};

let _allHomelabDomains: HomelabDomain[] | undefined = undefined;

export async function getAllHomelabDomains(): Promise<HomelabDomain[]> {
    _allHomelabDomains ??= await loadAllHomelabDomains();
    return _allHomelabDomains;
}

async function loadAllHomelabDomains(): Promise<HomelabDomain[]> {
    const appEntryUtilsPath = path.join(repositoryPath, 'docker-images', '.shared', 'build-utils', 'parse-app-entry-utils.sh');
    const appEntryParallelLimit = Math.max(1, Math.floor(os.cpus().length / 2));

    const servers = await fsx.readdir(path.join(repositoryPath, 'servers'), { withFileTypes: true });
    const appDirectories = (await pParallel(
        servers
            .filter((server) => server.isDirectory() && !server.name.startsWith('.'))
            .map((server) => async () => {
                const dockerAppsPath = path.join(repositoryPath, 'servers', server.name, 'docker-apps');
                try {
                    return (await fsx.readdir(dockerAppsPath, { withFileTypes: true }))
                        .filter((app) => app.isDirectory() && !app.name.startsWith('.'))
                        .map((app) => path.join(dockerAppsPath, app.name));
                } catch (error) {
                    if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
                        return [];
                    }
                    throw error;
                }
            }),
        appEntryParallelLimit,
    )).flat()
        .sort();

    const appDomains: HomelabDomain[] = await pParallel(
        appDirectories.map((appDirectory) => async () => {
            const { stdout } = await execa('sh', [
                '-c',
                '. "$1"; get_app_domain "$2"; get_app_ip "$2"',
                'sh',
                appEntryUtilsPath,
                appDirectory,
            ]);
            const [name, ip] = stdout.trim().split('\n');
            const ipVersion = net.isIP(ip);
            if (!name || (ipVersion !== 4 && ipVersion !== 6)) {
                throw new Error(`Could not parse the domain and IP for ${appDirectory}`);
            }
            return {
                name: name,
                ips: [{ type: ipVersion === 4 ? 'A' as const : 'AAAA', ip: ip }],
            } satisfies HomelabDomain;
        }),
        appEntryParallelLimit,
    );

    const extraDomains: HomelabDomain[] = (await fsx.readFile(path.join(repositoryPath, 'docker-images', 'pihole', 'app', 'extra-domains.txt'), 'utf8'))
        .split('\n')
        .flatMap<HomelabDomain>((line) => {
            const entries = line.replace(/#.*/, '').trim().split(/\s+/);
            const [value = '', ...names] = entries;
            const ipVersion = net.isIP(value);
            if (names.length === 0) {
                return [];
            }
            if (ipVersion === 4 || ipVersion === 6) {
                return names.map((name) => ({ name: name, ips: [{ type: ipVersion === 4 ? 'A' as const : 'AAAA', ip: value }] } satisfies HomelabDomain));
            }
            if (names.length === 1) {
                return [{ name: value, ips: [{ type: 'CNAME' as const, ip: names[0] }] } satisfies HomelabDomain];
            }
            return [];
        });

    const domains = Object.values(_.groupBy([...appDomains, ...extraDomains], 'name'))
        .map((domains) => {
            const ips = _.uniqBy(domains.flatMap((domain) => domain.ips), ({ type, ip }) => `${type}:${ip ?? ''}`);
            return {
                name: domains[0].name,
                ips: ips,
            };
        })
        .sort((lhs, rhs) => lhs.name.localeCompare(rhs.name));

    const domainsByName = new Map(domains.map((domain) => [domain.name, domain]));
    const resolveIps = (domain: HomelabDomain, cnamePath: string[] = [domain.name]): HomelabDomain['ips'] => domain.ips.flatMap((ip) => {
        if (ip.type !== 'CNAME') {
            return [ip];
        }
        if (cnamePath.includes(ip.ip)) {
            throw new Error(`CNAME loop detected: ${[...cnamePath, ip.ip].join(' -> ')}`);
        }
        const targetDomain = domainsByName.get(ip.ip);
        if (!targetDomain) {
            throw new Error(`Could not resolve CNAME ${domain.name} to ${ip.ip}`);
        }
        return [ip, ...resolveIps(targetDomain, [...cnamePath, ip.ip])];
    });

    return domains.map((domain) => ({
        name: domain.name,
        ips: _.uniqBy(resolveIps(domain), ({ type, ip }) => `${type}:${ip}`),
    }));
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

export function formatDuration(milliseconds: number): string {
    const duration = Temporal.Duration.from({ milliseconds: milliseconds }).round({
        largestUnit: "hour",
        smallestUnit: "millisecond",
    });
    return new Intl.DurationFormat("en", { style: "short" }).format(duration).replaceAll(/[, ]/g, '');
}

export function capitalize(text: string): string {
    return text
        .split('\n')
        .map((line) => line
            .split('-')
            .map((text) => _.capitalize(text))
            .join('-'),
        )
        .join('\n');
}
