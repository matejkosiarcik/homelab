import fs from 'node:fs/promises';
import fsSync from 'node:fs';
import path from 'node:path';
import dotenv from 'dotenv';
import { expect } from 'chai';

export function preprepare() {
    // Load .env file - Mostly useful for local (non-docker) debugging
    if (fsSync.existsSync('.env')) {
        dotenv.config({ path: '.env' });
    }
}

export function getIsoDate(): string {
    return new Date(new Date().getTime() - new Date().getTimezoneOffset() * 60 * 1000)
        .toISOString()
        .replaceAll(':', '-')
        .replaceAll('T', '_')
        .replace(/\..+$/, '');
}

export function getTargetUrl(): string {
    if (process.env['URL']) {
        return process.env['URL'];
    }

    if (fsSync.existsSync('/.dockerenv')) {
        switch (getAppName()) {
            case 'uptime-kuma': {
                return 'http://main-app:3001';
            }
            case 'omada-controller': {
                return process.env['HOMELAB_ENV'] === 'dev' ? 'http://main-app:8080' : 'http://main-app';
            }
            case 'unifi-controller': {
                return 'https://main-app:8443';
            }
            case 'speedtest-tracker': {
                return 'https://main-app';
            }
            default: {
                return 'http://main-app';
            }
        }
    }

    return 'https://localhost:8443';
}

export function getBrowserPath(): string | undefined {
    return process.env['BROWSER_PATH'] || undefined;
}

export function getAppName(): string {
    const appType = process.env['HOMELAB_APP_NAME']!;
    expect(appType, 'HOMELAB_APP_NAME unset').not.undefined;
    return appType;
}

export async function getDir(name: string): Promise<string> {
    const appType = getAppName();
    const directory = process.env[`HOMELAB_${name.toUpperCase()}_DIR`] || (fsSync.existsSync('/.dockerenv') ? `/${name}` : path.join(`.${name}`, appType));
    await fs.mkdir(directory, { recursive: true });
    return directory;
}

export async function getErrorAttachmentDir(): Promise<string> {
    const appName = getAppName();
    const errorDir = process.env['HOMELAB_ERROR_DIR'] || (fsSync.existsSync('/.dockerenv') ? '/errors' : path.join('.errors', appName));
    await fs.mkdir(errorDir, { recursive: true });
    return errorDir;
}

export function getIsHeadless(): boolean {
    return fsSync.existsSync('/.dockerenv') ? true : process.env['HEADLESS'] !== '0';
}

export function getCredentials(credentialType: 'username' | 'password'): string {
    const envName = `HOMELAB_APP_${credentialType.toUpperCase()}`;
    const value = process.env[envName]!;
    expect(value, `Credentials ${envName} unset`).not.undefined;
    return value;
}
