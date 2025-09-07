import path from 'node:path';
import { expect } from 'chai';
import { runAutomation } from '../.utils/main.ts';
import { getCredentials, getDir, getIsoDate, preprepare } from '../.utils/utils.ts';

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
        // Login
        await page.goto('/login');
        await page.locator('#privacy-agree-btn').click(); // Hide cookies

        // Wait for either setup-form or login-form to load
        const setupButtonSelector = '#step-create-next a[type=button]';
        const loginButtonSelector = '#loginBtn a[type=button]';
        await page.locator(`${setupButtonSelector},${loginButtonSelector}`).waitFor();
        const isSetupForm = await page.locator(setupButtonSelector).isVisible({ timeout: 0 });
        if (isSetupForm && process.env['CRON'] === '0') {
            console.log('Skipping backup (app not setup)');
            return;
        }

        // Login
        console.log('Performing backup');
        await page.locator('#username input[type="text"]').fill(options.credentials.username);
        await page.locator('#password input[type="password"]').fill(options.credentials.password);
        await page.locator(loginButtonSelector).click({ noWaitAfter: true });
        await page.waitForURL(/.*#dashboardGlobal$/);

        // Navigate to proper place in settings
        await page.goto('/#maintenance');
        await page.locator('a.s-button[title="Export"]:has-text("Export")').waitFor({ timeout: 25_000 });
        await page.locator('a.s-button[title="Export"]:has-text("Export")').scrollIntoViewIfNeeded();

        // Initiate download
        const downloadPromise = page.waitForEvent('download', { timeout: 25_000 });
        await page.locator('a.s-button[title="Export"]:has-text("Export")').click();

        // Handle download
        const download = await downloadPromise;
        expect(download.suggestedFilename(), `Unknown extension for downloaded file: ${download.suggestedFilename()}`).match(/\.cfg$/);
        await download.saveAs(path.join(options.backupDir, `${options.currentDate}-settings.cfg`));
    }, { date: options.currentDate, skipInitial: true });
})();
