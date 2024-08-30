import path from 'node:path';
import { expect } from 'chai';
import { getDir, getIsoDate, getCredentials, preprepare } from '../.utils/utils.ts';
import { runAutomation } from '../.utils/main.ts';

(async () => {
    preprepare();

    const options = {
        backupDir: await getDir('backup'),
        currentDate: getIsoDate(),
        credentials: {
            password: getCredentials('password'),
        },
    };

    const currentDate = getIsoDate();
    await runAutomation(async (page) => {
        // Login
        await page.goto('/admin/login.php');
        await page.locator('form#loginform input#loginpw').fill(options.credentials.password);
        await page.locator('form#loginform button[type="submit"]').click({ noWaitAfter: true });
        await page.waitForURL('/admin/index.php');

        // Navigate to proper place in settings
        await page.goto('/admin/settings.php?tab=teleporter');

        // Initiate download
        const downloadPromise = page.waitForEvent('download', { timeout: 10_000 });
        await page.locator('form#takeoutform button[type="submit"]:has-text("Backup")').click();

        // Handle download
        const download = await downloadPromise;
        expect(download.suggestedFilename(), `Unknown extension for downloaded file: ${download.suggestedFilename()}`).match(/\.tar\.gz$/);
        await download.saveAs(path.join(options.backupDir, `${currentDate}.tar.gz`));
    }, { date: options.currentDate });
})();
