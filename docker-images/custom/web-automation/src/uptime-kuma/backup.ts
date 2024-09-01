import path from 'node:path';
import { expect } from 'chai';
import { getCredentials, getDir, getIsoDate, preprepare } from '../.utils/utils.ts';
import { runAutomation } from '../.utils/main.ts';

(async () => {
    preprepare();

    const options = {
        backupDir: await getDir('backup'),
        currentDate: getIsoDate(),
        credentials: {
            username: getCredentials('username'),
            password: getCredentials('password'),
        },
    };

    await runAutomation(async (page) => {
        await page.goto('/dashboard');

        // Login
        await page.locator('form input[type="text"][autocomplete="username"]').fill(options.credentials.username);
        await page.locator('form input[type="password"][autocomplete="current-password"]').fill(options.credentials.password);
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
        await download.saveAs(path.join(options.backupDir, `${options.currentDate}.json`));
    }, { date: options.currentDate });
})();
