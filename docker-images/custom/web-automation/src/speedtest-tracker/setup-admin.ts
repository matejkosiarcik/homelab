import path from 'path';
import { expect } from 'chai';
import { commonStart, getDir, getIsoDate, getTargetAdminPassword, getTargetAdminUsername } from '../.utils/utils.ts';
import { runAutomation } from '../.utils/main.ts';

// TODO: Remove this script after it is possible to setup credentials via ENV variables
// https://github.com/alexjustesen/speedtest-tracker/issues/1597

(async () => {
    commonStart();

    const setup = {
        exportDir: await getDir('export'),
        credentials: {
            username: getTargetAdminUsername(),
            password: getTargetAdminPassword(),
        },
        currentDate: getIsoDate(),
    };

    await runAutomation(async (page) => {
        // Login
        await page.goto('/admin/login');

        // Try to login with default credentials
        await page.locator(`input[id="data.email"]`).fill('admin@example.com');
        await page.locator(`input[id="data.password"]`).fill('password');
        await page.locator('form#form .fi-form-actions button:has-text("Sign in")').click({ noWaitAfter: true });

        // Wait for login to finish or error message to be visible
        await Promise.any([page.waitForURL('/admin'), page.locator('text="These credentials do not match our records."').waitFor()]);
        if (page.url().endsWith('/login')) {
            console.log('Admin credentials already setup');
            return;
        }

        // Change credentials
        await page.goto('/admin/profile');
        await page.locator('input[id="data.email"]').clear();
        await page.locator('input[id="data.email"]').fill(setup.credentials.username);
        await page.locator('input[id="data.password"]').clear();
        await page.locator('input[id="data.password"]').fill(setup.credentials.password);
        await page.locator('input[id="data.passwordConfirmation"]').clear();
        await page.locator('input[id="data.passwordConfirmation"]').fill(setup.credentials.password);

        // Confirm changes
        await page.locator('button:has-text("Save changes")').click();
        await page.locator('.fi-no-notification:has-text("Saved")').waitFor({ timeout: 2000 });
        console.log('Admin credentials setup successfully');
    }, { date: setup.currentDate });
})();
