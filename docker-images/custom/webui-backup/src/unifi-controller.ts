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
        await page.goto('/manage/account/login');
        await page.locator('input[name="username"]').waitFor({ timeout: 5000 })
        await page.locator('input[name="username"]').fill(credentials.username);
        await page.locator('input[name="password"]').fill(credentials.password);
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
        expect(download.suggestedFilename(), `Unknown extension for downloaded file: ${download.suggestedFilename()}`).toMatch(/\.unf$/);
        await download.saveAs(getDownloadFilename({ backupDir: setup.backupDir, extension: 'unf', fileSuffix: '-settings' }));
    } finally {
        await browser.close();
    }
})();
