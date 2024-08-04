import fsSync from 'fs';
import fs from 'fs/promises';
import path from 'path';
import dotenv from 'dotenv';
import { Browser, expect, Page } from 'playwright/test';

export function getIsoDate(): string {
    return new Date(new Date().getTime() - new Date().getTimezoneOffset() * 60 * 1000)
        .toISOString()
        .replaceAll(':', '-')
        .replaceAll('T', '_')
        .replace(/\..+$/, '');
}

export function loadEnv() {
    if (fsSync.existsSync('.env')) {
        dotenv.config({ path: '.env' });
    }
}

export function getTargetUrl(): string {
    return process.env['URL'] || (fsSync.existsSync('/.dockerenv') ? 'http://main-app' : 'https://localhost:8443');
}

export function getBrowserPath(): string | undefined {
    return process.env['BROWSER_PATH'] || (fsSync.existsSync('/.dockerenv') ? '/usr/bin/chromium' : undefined);
}

export async function getBackupDir(): Promise<string> {
    const appType = process.env['HOMELAB_APP_TYPE'] || 'unknown';
    const backupDir = process.env['HOMELAB_BACKUP_DIR'] || (fsSync.existsSync('/.dockerenv') ? '/backup' : path.join('data', appType));
    await fs.mkdir(backupDir, { recursive: true });
    return backupDir;
}

export function getIsHeadless(): boolean {
    return fsSync.existsSync('/.dockerenv') ? true : process.env['HEADLESS'] !== '0';
}

export function getTargetAdminUsername(): string {
    const username = process.env['HOMELAB_APP_USERNAME']!;
    expect(username, 'HOMELAB_APP_USERNAME unset').toBeTruthy();
    return username;
}

export function getTargetAdminPassword(): string {
    const password = process.env['HOMELAB_APP_PASSWORD']!;
    expect(password, 'HOMELAB_APP_PASSWORD unset').toBeTruthy();
    return password;
}

export function getDownloadFilename(options: { backupDir: string, extension: string, fileSuffix?: string | undefined }): string {
    return path.join(options.backupDir, `${getIsoDate()}${options.fileSuffix ?? ''}.${options.extension}`);
}

export async function newPage(browser: Browser, baseUrl: string): Promise<Page> {
    const page = await browser.newPage({ baseURL: baseUrl, strictSelectors: true, ignoreHTTPSErrors: true });
    page.setDefaultNavigationTimeout(10_000);
    page.setDefaultTimeout(1000);
    return page;
}
