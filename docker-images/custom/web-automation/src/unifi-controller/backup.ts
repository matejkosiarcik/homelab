import path from 'path';
import { expect } from 'chai';
import { getBackupDir, getIsoDate, getTargetAdminPassword, getTargetAdminUsername } from '../.utils/utils.ts';
import { runAutomation } from '../.utils/main.ts';

(async () => {
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

        // Wait for either setup-form or login-form to load
        const controllerNameInputSelector = 'input#controllerName';
        const loginNameInputSelector = 'input[name="username"]';
        await page.locator(`${controllerNameInputSelector},${loginNameInputSelector}`).waitFor({ timeout: 5000 });
        const isSetupForm = await page.locator(controllerNameInputSelector).isVisible({ timeout: 0 });
        if (isSetupForm && process.env['CRON'] === '0') {
            console.log('Quitting backup, because app is not setup yet.');
            return;
        }

        await page.locator(loginNameInputSelector).fill(credentials.username);
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
