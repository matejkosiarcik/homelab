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
    const url = process.env['URL'] || (fsSync.existsSync('/.dockerenv') ? 'https://omada-controller-app:8443' : 'https://localhost:8443');
    const headless = process.env['HEADLESS'] !== '0';
    const username = process.env['USERNAME']!;
    expect(username, 'USERNAME unset').toBeTruthy();
    const password = process.env['PASSWORD']!;
    expect(password, 'PASSWORD unset').toBeTruthy();

    const _date = new Date(new Date().getTime() - new Date().getTimezoneOffset() * 60 * 1000);
    const backupDate = _date.toISOString().replaceAll(':', '-').replaceAll('T', '_').replace(/\..+$/, '');
    await fs.mkdir(backupDir, { recursive: true });

    const browser = await chromium.launch({ headless: headless, executablePath: browserPath });
    try {
        const page = await browser.newPage({ baseURL: url, strictSelectors: true, ignoreHTTPSErrors: true });
        page.setDefaultNavigationTimeout(10_000);
        page.setDefaultTimeout(1000);

        // Login
        await page.goto('/login');
        await page.locator('#privacy-agree-btn').click(); // Hide cookies
        await page.locator('#username input[type="text"]').fill(username);
        await page.locator('#password input[type="password"]').fill(password);
        await page.locator('#loginBtn a[type=button]').click({ noWaitAfter: true });
        await page.waitForURL(/.*#dashboardGlobal$/);

        // Navigate to proper place in settings
        await page.goto('/#maintenance');
        await page.locator('a.s-button[title="Export"]:has-text("Export")').waitFor({ timeout: 10_000 });
        await page.locator('a.s-button[title="Export"]:has-text("Export")').scrollIntoViewIfNeeded();

        // Initiate download
        const downloadPromise = page.waitForEvent('download', { timeout: 15_000 });
        await page.locator('a.s-button[title="Export"]:has-text("Export")').click();

        // Handle download
        const download = await downloadPromise;
        const extension = path.extname(download.suggestedFilename()).slice(1);
        expect(extension, `Unknown extension for downloaded file: ${download.suggestedFilename()}`).toEqual('cfg');
        await download.saveAs(path.join(backupDir, `${backupDate}-settings.${extension}`));
    } finally {
        await browser.close();
    }
})();
