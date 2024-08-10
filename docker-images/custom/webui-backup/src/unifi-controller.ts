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
        expect(download.suggestedFilename(), `Unknown extension for downloaded file: ${download.suggestedFilename()}`).match(/\.unf$/);
        await download.saveAs(path.join(setup.backupDir, `${currentDate}-settings.unf`));
    }, { date: currentDate });
})();
