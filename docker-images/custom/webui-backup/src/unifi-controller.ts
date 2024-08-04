import fs from 'fs/promises';
import fsSync from 'fs';
import path from 'path';
import process from 'process';
import dotenv from 'dotenv';
import { chromium } from 'playwright';
import { expect } from 'playwright/test';
import { getIsoDate } from './utils/utils.ts';

(async () => {
    // Env config
    if (fsSync.existsSync('.env')) {
        dotenv.config({ path: '.env' });
    }

    const backupDir = process.env['BACKUP_DIR'] || (fsSync.existsSync('/.dockerenv') ? '/backup' : './data');
    const browserPath = process.env['BROWSER_PATH'] || (fsSync.existsSync('/.dockerenv') ? '/usr/bin/chromium' : undefined);
    const url = process.env['URL'] || (fsSync.existsSync('/.dockerenv') ? 'https://unifi-controller-app:8443' : 'https://localhost:8443');
    const headless = process.env['HEADLESS'] !== '0';
    const username = process.env['USERNAME']!;
    expect(username, 'USERNAME unset').toBeTruthy();
    const password = process.env['PASSWORD']!;
    expect(password, 'PASSWORD unset').toBeTruthy();
    await fs.mkdir(backupDir, { recursive: true });

    const browser = await chromium.launch({ headless: headless, executablePath: browserPath });
    try {
        const page = await browser.newPage({ baseURL: url, strictSelectors: true, ignoreHTTPSErrors: true });
        page.setDefaultNavigationTimeout(10_000);
        page.setDefaultTimeout(1000);

        // Login
        await page.goto('/manage/account/login');
        await page.locator('input[name="username"]').waitFor({ timeout: 5000 })
        await page.locator('input[name="username"]').fill(username);
        await page.locator('input[name="password"]').fill(password);
        await page.locator('button#loginButton').click({ noWaitAfter: true });
        await page.waitForURL('/manage/default/dashboard');

        // Navigate to proper place in settings
        await page.goto('/manage/default/settings/system');
        await page.locator('button[data-testid="system-backups-toggle"]').waitFor({ timeout: 10_000 });
        await page.locator('button[data-testid="system-backups-toggle"]').click();
        await page.locator('button[name="backupDownload"]').click();

        // Initiate download
        const downloadPromise = page.waitForEvent('download', { timeout: 15_000 });
        await page.locator('button[name="backupDownload"]').last().click();

        // Handle download
        const download = await downloadPromise;
        const extension = path.extname(download.suggestedFilename()).slice(1);
        expect(extension, `Unknown extension for downloaded file: ${download.suggestedFilename()}`).toEqual('unf');
        await download.saveAs(path.join(backupDir, `${getIsoDate()}-settings.${extension}`));
    } finally {
        await browser.close();
    }
})();
