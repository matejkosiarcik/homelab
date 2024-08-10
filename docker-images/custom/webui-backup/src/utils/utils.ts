import fs from 'fs/promises';
import fsSync from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import { expect } from 'chai';

export function loadEnv() {
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
    return process.env['URL'] || (fsSync.existsSync('/.dockerenv') ? 'http://main-app' : 'https://localhost:8443');
}

export function getBrowserPath(): string | undefined {
    return process.env['BROWSER_PATH'] || (fsSync.existsSync('/.dockerenv') ? '/usr/bin/chromium' : undefined);
}

export function getAppType(): string {
    const appType = process.env['HOMELAB_APP_TYPE']!;
    expect(appType, 'HOMELAB_APP_TYPE unset').not.undefined;
    return appType;
}

export async function getBackupDir(): Promise<string> {
    const appType = getAppType();
    const backupDir = process.env['HOMELAB_BACKUP_DIR'] || (fsSync.existsSync('/.dockerenv') ? '/backup' : path.join('data', appType));
    await fs.mkdir(backupDir, { recursive: true });
    return backupDir;
}

export async function getErrorAttachmentDir(): Promise<string> {
    const appType = getAppType();
    const errorDir = process.env['HOMELAB_ERROR_DIR'] || (fsSync.existsSync('/.dockerenv') ? '/error' : path.join('error', appType));
    await fs.mkdir(errorDir, { recursive: true });
    return errorDir;
}

export function getIsHeadless(): boolean {
    return fsSync.existsSync('/.dockerenv') ? true : process.env['HEADLESS'] !== '0';
}

export function getTargetAdminUsername(): string {
    const username = process.env['HOMELAB_APP_USERNAME']!;
    expect(username, 'HOMELAB_APP_USERNAME unset').not.undefined;
    return username;
}

export function getTargetAdminPassword(): string {
    const password = process.env['HOMELAB_APP_PASSWORD']!;
    expect(password, 'HOMELAB_APP_PASSWORD unset').not.undefined;
    return password;
}
