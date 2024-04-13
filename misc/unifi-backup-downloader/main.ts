import fs from 'fs/promises';
import path from 'path';
import { chromium } from 'playwright';

(async () => {
    // TODO: Make these values real
    const url = 'https://localhost:8443';
    const username = 'admin';
    const password = 'Password123.'

    await fs.mkdir('data', { recursive: true });
    const date = new Date().toISOString().replaceAll(':', '-').replaceAll('T', '_').replace(/\..+$/, '');

    const browser = await chromium.launch({ headless: false });
    try {
        const page = await browser.newPage({ baseURL: url, strictSelectors: true, ignoreHTTPSErrors: true });
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
        const downloadPromise = page.waitForEvent('download');
        await page.locator('button[name="backupDownload"]').last().click();

        // Handle download
        const download = await downloadPromise;
        const extension = path.extname(download.suggestedFilename()).slice(1);
        if (extension !== 'unf') {
            throw new Error(`Unknown extension for downloaded file: ${download.suggestedFilename()}`);
        }
        const downloadPath = path.join('data', `${date}-settings.${extension}`);
        await download.saveAs(downloadPath);
    } finally {
        await browser.close();
    }
})();
