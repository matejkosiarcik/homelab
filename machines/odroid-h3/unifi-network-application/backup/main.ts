import fs from 'fs/promises';
import fsSync from 'fs';
import path from 'path';
import process from 'process';
import { chromium } from 'playwright';
import dotenv from 'dotenv';

(async () => {
    if (fsSync.existsSync('.env')) {
        dotenv.config({ path: '.env' });
    }

    const backupsDir = process.env['BACKUPS_DIR'] || '/backup';
    const browserPath = process.env['BROWSER_PATH'] || undefined;

    const url = process.env['URL'];
    if (!url) {
        throw new Error('URL unset');
    }

    const username = process.env['USERNAME'];
    if (!username) {
        throw new Error('USERNAME unset');
    }

    const password = process.env['PASSWORD'];
    if (!password) {
        throw new Error('PASSWORD unset');
    }

    if (!fsSync.existsSync(backupsDir)) {
        await fs.mkdir(backupsDir, { recursive: true });
    }
    const backupDate = new Date().toISOString().replaceAll(':', '-').replaceAll('T', '_').replace(/\..+$/, '');

    const browser = await chromium.launch({ headless: true, executablePath: browserPath });
    try {
        const page = await browser.newPage({ baseURL: url, strictSelectors: true, ignoreHTTPSErrors: true });
        page.setDefaultNavigationTimeout(10_000);
        page.setDefaultTimeout(2000);
        await page.goto('/');

        // Login
        await page.locator('input[name="username"]').fill(username);
        await page.locator('input[name="password"]').fill(password);
        await page.locator('button#loginButton').click();
        await page.waitForURL('/manage/default/dashboard');

        // Navigate to proper place in settings
        await page.goto('/manage/default/settings/system');
        await page.locator('button[data-testid="system-backups-toggle"]').click();
        await page.locator('button[name="backupDownload"]').click();

        // Initiate download
        const downloadPromise = page.waitForEvent('download', { timeout: 15_000 });
        await page.locator('button[name="backupDownload"]').last().click();

        // Handle download
        const download = await downloadPromise;
        const extension = path.extname(download.suggestedFilename()).slice(1);
        if (extension !== 'unf') {
            throw new Error(`Unknown extension for downloaded file: ${download.suggestedFilename()}`);
        }
        const downloadPath = path.join(backupsDir, `${backupDate}-settings.${extension}`);
        await download.saveAs(downloadPath);
    } finally {
        await browser.close();
    }
})();
