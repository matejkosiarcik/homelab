import fs from 'fs/promises';
import fsSync from 'fs';
import path from 'path';
import process from 'process';
import { chromium } from 'playwright';
import dotenv from 'dotenv';
import { expect } from 'playwright/test';

(async () => {
    if (fsSync.existsSync('.env')) {
        dotenv.config({ path: '.env' });
    }

    const backupDir = process.env['BACKUP_DIR'] || '/backup';
    const browserPath = process.env['BROWSER_PATH'] || undefined;

    const url = process.env['URL'];
    if (!url) {
        throw new Error('URL unset');
    }

    const password = process.env['PASSWORD'];
    if (!password) {
        throw new Error('PASSWORD unset');
    }

    if (!fsSync.existsSync(backupDir)) {
        await fs.mkdir(backupDir, { recursive: true });
    }
    const backupDate = new Date().toISOString().replaceAll(':', '-').replaceAll('T', '_').replace(/\..+$/, '');

    const browser = await chromium.launch({ headless: true, executablePath: browserPath });
    try {
        const page = await browser.newPage({ baseURL: url, strictSelectors: true, ignoreHTTPSErrors: true });
        page.setDefaultNavigationTimeout(10_000);
        page.setDefaultTimeout(2000);
        await page.goto('/admin/settings.php');

        // Login
        await page.waitForURL(/login/);
        await page.locator('form#loginform input#loginpw').fill(password);
        await page.locator('form#loginform button[type="submit"]').click();
        await page.waitForURL('/admin/settings.php');

        // Navigate to proper place in settings
        await page.goto('/admin/settings.php?tab=teleporter');

        // Initiate download
        const downloadPromise = page.waitForEvent('download', { timeout: 10_000 });
        await page.locator('form#takeoutform button[type="submit"]:has-text("Backup")').click();

        // Handle download
        const download = await downloadPromise;
        if (!/\.tar\.gz$/.test(download.suggestedFilename())) {
            throw new Error(`Unknown extension for downloaded file: ${download.suggestedFilename()}`);
        }
        const downloadPath = path.join(backupDir, download.suggestedFilename().replace(/^.+(\.tar\.gz)$/, `${backupDate}-settings$1`));
        await download.saveAs(downloadPath);
    } finally {
        await browser.close();
    }
})();
