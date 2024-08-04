import { chromium } from 'playwright';
import { expect } from 'playwright/test';
import { getBackupDir, getBrowserPath, getDownloadFilename, getIsHeadless, getIsoDate, getTargetAdminPassword, getTargetUrl, loadEnv, newPage } from './utils/utils.ts';

(async () => {
    loadEnv();
    const setup = {
        backupDir: await getBackupDir(),
        browserPath: getBrowserPath(),
        isHeadless: getIsHeadless(),
        url: getTargetUrl(),
    };
    const credentials = {
        password: getTargetAdminPassword(),
    };

    const browser = await chromium.launch({ headless: setup.isHeadless, executablePath: setup.browserPath });
    try {
        const page = await newPage(browser, setup.url);

        // Login
        await page.goto('/admin/login.php');
        await page.locator('form#loginform input#loginpw').fill(credentials.password);
        await page.locator('form#loginform button[type="submit"]').click({ noWaitAfter: true });
        await page.waitForURL('/admin/index.php');

        // Navigate to proper place in settings
        await page.goto('/admin/settings.php?tab=teleporter');

        // Initiate download
        const downloadPromise = page.waitForEvent('download', { timeout: 10_000 });
        await page.locator('form#takeoutform button[type="submit"]:has-text("Backup")').click();

        // Handle download
        const download = await downloadPromise;
        expect(download.suggestedFilename(), `Unknown extension for downloaded file: ${download.suggestedFilename()}`).toMatch(/\.tar\.gz$/);
        await download.saveAs(getDownloadFilename({ backupDir: setup.backupDir, extension: 'tar.gz' }));
    } finally {
        await browser.close();
    }
})();
