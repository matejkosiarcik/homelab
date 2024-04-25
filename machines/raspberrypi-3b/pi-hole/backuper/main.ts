import fs from 'fs/promises';
import fsSync from 'fs';
import path from 'path';
import process from 'process';
import dotenv from 'dotenv';
import { chromium } from 'playwright';
import { expect } from 'playwright/test';

(async () => {
    // Env config
    if (fsSync.existsSync('.env')) {
        dotenv.config({ path: '.env' });
    }
    const backupDir = process.env['BACKUP_DIR'] || (fsSync.existsSync('/.dockerenv') ? '/backup' : './data');
    const browserPath = process.env['BROWSER_PATH'] || (fsSync.existsSync('/.dockerenv') ? '/usr/bin/chromium' : undefined);
    const url = process.env['URL'] || 'http://localhost:8080';
    const headless = process.env['HEADLESS'] !== '0';
    const password = process.env['PASSWORD']!;
    expect(password, 'PASSWORD unset').toBeTruthy();

    const backupDate = new Date().toISOString().replaceAll(':', '-').replaceAll('T', '_').replace(/\..+$/, '');
    await fs.mkdir(backupDir, { recursive: true });

    const browser = await chromium.launch({ headless: headless, executablePath: browserPath });
    try {
        const page = await browser.newPage({ baseURL: url, strictSelectors: true, ignoreHTTPSErrors: true });
        page.setDefaultNavigationTimeout(10_000);
        page.setDefaultTimeout(1000);
        await page.goto('/admin/login.php');

        // Login
        await page.locator('form#loginform input#loginpw').fill(password);
        await page.locator('form#loginform button[type="submit"]').click();
        await page.waitForURL('/admin/index.php');

        // Navigate to proper place in settings
        await page.goto('/admin/settings.php?tab=teleporter');

        // Initiate download
        const downloadPromise = page.waitForEvent('download', { timeout: 10_000 });
        await page.locator('form#takeoutform button[type="submit"]:has-text("Backup")').click();

        // Handle download
        const download = await downloadPromise;
        expect(download.suggestedFilename(), `Unknown extension for downloaded file: ${download.suggestedFilename()}`).toMatch(/\.tar\.gz/);
        await download.saveAs(path.join(backupDir, `${backupDate}.tar.gz`));
    } finally {
        await browser.close();
    }
})();
