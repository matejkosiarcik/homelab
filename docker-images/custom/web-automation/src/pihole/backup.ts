import path from 'path';
import { expect } from 'chai';
import { getDir, getIsoDate, getTargetAdminPassword } from '../.utils/utils.ts';
import { runAutomation } from '../.utils/main.ts';

(async () => {
    const setup = {
        backupDir: await getDir('backup'),
    };
    const credentials = {
        password: getTargetAdminPassword(),
    };

    const currentDate = getIsoDate();
    await runAutomation(async (page) => {
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
        expect(download.suggestedFilename(), `Unknown extension for downloaded file: ${download.suggestedFilename()}`).match(/\.tar\.gz$/);
        await download.saveAs(path.join(setup.backupDir, `${currentDate}.tar.gz`));
    }, { date: currentDate });
})();
