import path from 'path';
import { expect } from 'chai';
import { getDir, getIsoDate, getTargetAdminPassword, getTargetAdminUsername } from '../.utils/utils.ts';
import { runAutomation } from '../.utils/main.ts';

(async () => {
    const options = {
        backupDir: await getDir('backup'),
        currentDate: getIsoDate(),
        credentials: {
            username: getTargetAdminUsername(),
            password: getTargetAdminPassword(),
        },
    };

    await runAutomation(async (page) => {
        await page.goto('/dashboard');

        // Wait for either setup-form or login-form to load
        const setupButtonSelector = 'form button[type="submit"]:has-text("Create")';
        const loginButtonSelector = 'form button[type="submit"]:has-text("Login")';
        await page.locator(`${setupButtonSelector},${loginButtonSelector}`).waitFor({ timeout: 5000 });
        const isSetupForm = await page.locator(setupButtonSelector).isVisible({ timeout: 0 });
        if (isSetupForm && process.env['CRON'] === '0') {
            console.log('Quitting backup, because app is not setup yet.');
            return;
        }

        // Login
        await page.locator('form input[type="text"][autocomplete="username"]').fill(options.credentials.username);
        await page.locator('form input[type="password"][autocomplete="current-password"]').fill(options.credentials.password);
        await page.locator(loginButtonSelector).click();
        await page.locator('ul.nav .nav-link .profile-pic').waitFor({ timeout: 10_000 });

        // Navigate to proper place in settings
        await page.goto('/settings/backup');
        await page.locator('.settings-content button:has-text("Export")').waitFor({ timeout: 5000 });

        // Initiate download
        const downloadPromise = page.waitForEvent('download', { timeout: 15_000 });
        await page.locator('.settings-content button:has-text("Export")').click();

        // Handle download
        const download = await downloadPromise;
        expect(download.suggestedFilename(), `Unknown extension for downloaded file: ${download.suggestedFilename()}`).match(/\.json$/);
        await download.saveAs(path.join(options.backupDir, `${options.currentDate}.json`));
    }, { date: options.currentDate });
})();
