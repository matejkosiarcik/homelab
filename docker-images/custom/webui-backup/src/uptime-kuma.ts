import path from 'path';
import { expect } from 'chai';
import { getBackupDir, getIsoDate, getTargetAdminPassword, getTargetAdminUsername, loadEnv } from './utils/utils.ts';
import { runAutomation } from './utils/main.ts';

(async () => {
    loadEnv();

    const setup = {
        backupDir: await getBackupDir(),
    };
    const credentials = {
        username: getTargetAdminUsername(),
        password: getTargetAdminPassword(),
    };
    const currentDate = getIsoDate();

    await runAutomation(async (page) => {
        await page.goto('/dashboard');

        const isSetupForm = await (async () => {
            try {
                await page.locator('[data-cy="setup-form"]').waitFor({ timeout: 2000 });
                return true;
            } catch {
                return false;
            }
        })();
        if (isSetupForm) {
            console.log('Quitting backup, because app is not setup yet.');
            return;
        }

        // Login
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
        expect(download.suggestedFilename(), `Unknown extension for downloaded file: ${download.suggestedFilename()}`).match(/\.json$/);
        await download.saveAs(path.join(setup.backupDir, `${currentDate}.json`));
    }, { date: currentDate });
})();
