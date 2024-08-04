import fs from 'fs/promises';
import fsSync from 'fs';
import path from 'path';
import process from 'process';
import dotenv from 'dotenv';
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
        await page.goto('/dashboard');
        await page.locator('form input[type="text"][autocomplete="username"]').fill(credentials.username);
        await page.locator('form input[type="password"][autocomplete="current-password"]').fill(credentials.password);
        await page.locator('form button[type="submit"]:has-text("Login")').click();
        await page.locator('ul.nav .nav-link .profile-pic').waitFor({ timeout: 10_000 });

        // Navigate to proper place in settings
        await page.goto('/settings/backup');
        await page.locator('.settings-content button:has-text("Export")').waitFor({ timeout: 5000 });

        // Initiate download
        const downloadPromise = page.waitForEvent('download', { timeout: 15_000 });
        await page.locator('.settings-content button:has-text("Export")').click();

        // Handle download
        const download = await downloadPromise;
        expect(download.suggestedFilename(), `Unknown extension for downloaded file: ${download.suggestedFilename()}`).toMatch(/\.json$/);
        await download.saveAs(getDownloadFilename({ backupDir: setup.backupDir, extension: 'json' }));
    } finally {
        await browser.close();
    }
})();
