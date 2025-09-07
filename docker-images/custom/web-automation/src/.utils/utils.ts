import fs from 'node:fs/promises';
import fsSync from 'node:fs';
import path from 'node:path';
import dotenv from 'dotenv';
import { expect } from 'chai';
import { type Locator, type Page } from 'playwright';
import { randomInt } from 'node:crypto';

export function preprepare() {
    // Load .env file - Mostly useful for local (non-docker) debugging
    if (fsSync.existsSync('.env')) {
        dotenv.config({ path: '.env', quiet: true  });
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
    if (process.env['HOMELAB_BASE_URL']) {
        return process.env['HOMELAB_BASE_URL'];
    }

    if (fsSync.existsSync('/.dockerenv')) {
        switch (getAppName()) {
            case 'homeassistant': {
                return 'http://homeassistant:8123';
            }
            case 'omadacontroller': {
                return process.env['HOMELAB_ENV'] === 'dev' ? 'https://omadacontroller:8443' : 'https://omadacontroller';
            }
            case 'pihole': {
                return 'http://pihole';
            }
            case 'unificontroller': {
                return process.env['HOMELAB_ENV'] === 'dev' ? 'https://unifi-network-application:8443' : 'https://unifi-network-application:8443';
            }
            default: {
                throw new Error(`Unknow app: ${getAppName()}`);
            }
        }
    }

    return 'https://localhost:8443';
}

export function getBrowserPath(): string | undefined {
    return process.env['BROWSER_PATH'] || undefined;
}

export function getAppName(): string {
    const appType = process.env['HOMELAB_APP_TYPE']!;
    expect(appType, 'HOMELAB_APP_TYPE unset').not.undefined;
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
    const errorDir = process.env['HOMELAB_ERROR_DIR'] || (fsSync.existsSync('/.dockerenv') ? '/homelab/errors' : path.join('.errors', appName));
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

export async function getVisibleLocator(page: Page, selector: string): Promise<Locator> {
    for (const locator of await page.locator(selector).all()) {
        if (await locator.isVisible({ timeout: 0 })) {
            return locator;
        }
    }
    throw new Error(`Visible locator for selector '${selector}' not found`);
}

export async function delay(timeout: number): Promise<void> {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve();
        }, timeout);
    })
}

export async function retry<T>(options: {
    action: () => T | Promise<T>,
    retries: number,
    delay: number,
}): Promise<T> {
    let lastError: Error | undefined;
    for (let currentRetry = 0; currentRetry <= options.retries; currentRetry += 1) {
        try {
            let value = options.action();
            if (typeof value === 'object' && value && 'then' in value) {
                value = await value;
            }
            return value;
        } catch (error) {
            lastError = error as Error;
        }

        if (currentRetry < options.retries) {
            await delay(options.delay);
        }
    }
    throw lastError;
}
