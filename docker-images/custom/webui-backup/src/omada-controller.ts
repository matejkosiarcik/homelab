import { chromium } from 'playwright';
import { expect } from 'playwright/test';
import { getBackupDir, getBrowserPath, getDownloadFilename, getIsHeadless, getIsoDate, getTargetAdminPassword, getTargetAdminUsername, getTargetUrl, loadEnv, newPage } from './utils/utils.ts';

(async () => {
    loadEnv();
    const setup = {
        backupDir: await getBackupDir(),
        browserPath: getBrowserPath(),
        isHeadless: getIsHeadless(),
        url: getTargetUrl(),
    };
    const credentials = {
        username: getTargetAdminUsername(),
        password: getTargetAdminPassword(),
    };

    const browser = await chromium.launch({ headless: setup.isHeadless, executablePath: setup.browserPath });
    try {
        const page = await newPage(browser, setup.url);

        // Login
        await page.goto('/login');
        await page.locator('#privacy-agree-btn').click(); // Hide cookies
        await page.locator('#username input[type="text"]').fill(credentials.username);
        await page.locator('#password input[type="password"]').fill(credentials.password);
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
        expect(download.suggestedFilename(), `Unknown extension for downloaded file: ${download.suggestedFilename()}`).toMatch(/\.cfg$/);
        await download.saveAs(getDownloadFilename({ backupDir: setup.backupDir, extension: 'cfg', fileSuffix: '-settings' }));
    } finally {
        await browser.close();
    }
})();
