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
        await page.goto('/login');
        await page.locator('#privacy-agree-btn').click(); // Hide cookies

        // Wait for either setup-form or login-form to load
        const setupButtonSelector = '#step-create-next a[type=button]';
        const loginButtonSelector = '#loginBtn a[type=button]';
        await page.locator(`${setupButtonSelector},${loginButtonSelector}`).waitFor();
        const isSetupForm = await page.locator(setupButtonSelector).isVisible({ timeout: 0 });
        if (isSetupForm && process.env['CRON'] === '0') {
            console.log('Quitting backup, because app is not setup yet.');
            return;
        }

        await page.locator('#username input[type="text"]').fill(credentials.username);
        await page.locator('#password input[type="password"]').fill(credentials.password);
        await page.locator(loginButtonSelector).click({ noWaitAfter: true });
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
        expect(download.suggestedFilename(), `Unknown extension for downloaded file: ${download.suggestedFilename()}`).match(/\.cfg$/);
        await download.saveAs(path.join(setup.backupDir, `${currentDate}-settings.cfg`));
    }, { date: currentDate });
})();
