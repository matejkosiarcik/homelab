import fs from 'node:fs/promises';
import { getCredentials, getDir, getIsoDate, getVisibleLocator, preprepare } from '../.utils/utils.ts';
import { runAutomation } from '../.utils/main.ts';

(async () => {
    preprepare();

    if (process.env['CRON'] === '1') {
        console.log('Skipping scheduled admin-setup');
        return;
    }

    const options = {
        backupDir: await getDir('backup'),
        currentDate: getIsoDate(),
        credentials: {
            username: getCredentials('username'),
            password: getCredentials('password'),
        },
    };

    await runAutomation(async (page) => {
        await page.goto('/', { timeout: 30_000 });
        await page.locator('div[id^="nx-header-panel-"]').first().waitFor({ timeout: 20_000 });
        await page.locator('a[id^="nx-header-signin-"]:has-text("Sign in")').click();

        // Check if login modal contains initial admin warning
        await page.locator('div[id^="nx-signin-"][id$="-body"] div[id^="form-"][id$="-body"]').waitFor();
        if (!(await page.locator('div[id="signin-message"]').isVisible())) {
            console.log('Skipping admin credentials (already setup)');
            return;
        }
        if (!(await page.locator('div[id="signin-message"]').innerText()).includes('/nexus-data/admin.password')) {
            console.log('Skipping admin credentials (already setup)');
            return;
        }

        console.log('Setting up admin credentials');
        const currentUsername = 'admin';
        const currentPassword = (await fs.readFile('/homelab/app-data/admin.password', 'utf8')).trim();

        // Fill current credentials
        await page.locator('div[id^="nx-signin-"] input[name="username"]').fill(currentUsername);
        await page.locator('div[id^="nx-signin-"] input[type="password"][name="password"]').fill(currentPassword);
        await page.locator('div[id^="nx-signin-"] a[id^="button-"]:has-text("Sign in")').click();

        // Complete installation wizard
        await page.locator('div[id^="nx-onboarding-wizard-"]').first().waitFor({ timeout: 15_000 });
        // Step 1
        await (await getVisibleLocator(page, 'div[id^="nx-onboarding-wizard-"] a[id^="button-"]:has-text("Next")')).click();
        // Step 2
        await page.locator('div[id^="nx-onboarding-wizard-"] input[type="password"][name="password"]').fill(options.credentials.password); // Main password field
        await page.locator('div[id^="nx-onboarding-wizard-"] input[type="password"]:not([name="password"])').fill(options.credentials.password); // Confirm password field
        await (await getVisibleLocator(page, 'div[id^="nx-onboarding-wizard-"] a[id^="button-"]:has-text("Next")')).click();
        // Step 3
        await page.locator('div[id^="nx-onboarding-wizard-"] span:has(> input[type="radio"][name="configureAnonymous"]):has(~ label:has-text("Disable anonymous access")) > input[type="radio"][name="configureAnonymous"]').click();
        await (await getVisibleLocator(page, 'div[id^="nx-onboarding-wizard-"] a[id^="button-"]:has-text("Next")')).click();
        // Step 4
        await page.locator('div[id^="nx-onboarding-wizard-"] a[id^="button-"]:has-text("Finish")').click();

        // Wait for wizard to hide and signout
        await page.locator('div[id^="nx-onboarding-wizard-"]').waitFor({ state: 'hidden' });
        await page.locator('a[id^="nx-header-signout-"]:has-text("Sign out")').click();
        await page.waitForTimeout(1000);
    }, { date: options.currentDate });
})();
