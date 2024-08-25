import path from 'path';
import { expect } from 'chai';
import { preprepare, getDir, getIsoDate, getCredentials } from '../.utils/utils.ts';
import { runAutomation } from '../.utils/main.ts';

(async () => {
    preprepare();

    const options = {
        exportDir: await getDir('export'),
        currentDate: getIsoDate(),
        credentials: {
            username: getCredentials('username'),
            password: getCredentials('password'),
        },
    };

    await runAutomation(async (page) => {
        // Login
        await page.goto('/admin/login');

        await page.locator(`input[id="data.email"]`).fill(options.credentials.username);
        await page.locator(`input[id="data.password"]`).fill(options.credentials.password);
        await page.locator('form#form .fi-form-actions button:has-text("Sign in")').click({ noWaitAfter: true });
        await page.waitForURL('/admin');

        // Navigate to proper place in settings
        await page.goto('/admin/results');

        // Clear notifications first
        await page.locator('button.fi-topbar-database-notifications-btn').click();
        await page.locator('button:has-text("Clear"),h2:has-text("No notifications")').waitFor();
        if (await page.locator('button:has-text("Clear")').isVisible()) {
            await page.locator('button:has-text("Clear")').click();
        }
        await page.locator('button.fi-modal-close-btn').click();

        // Initiate export
        await page.locator('.fi-resource-results button:has-text("Export")').click();
        await page.locator('.fi-modal-window input[type="checkbox"]').first().waitFor();
        for (const checkbox of await page.locator('.fi-modal-window input[type="checkbox"]').all()) {
            const id = (await checkbox.getAttribute('id')) ?? '';
            const inputId = id.replace(/\.isEnabled$/, '.label');
            if (await page.locator(`input[id="${inputId}"]`).isDisabled()) {
                await checkbox.click();
                await page.locator(`input[id="${inputId}"]`).click(); // This basically ensures the input is enabled and nothing else
            }
        }
        await page.locator('.fi-modal-footer-actions button:has-text("Export")').click();
        await page.locator('.fi-no-notification').waitFor({ timeout: 5000 });
        await page.locator('.fi-no-notification').waitFor({ state: 'hidden', timeout: 10_000 });
        await page.locator('button.fi-topbar-database-notifications-btn').click();
        await page.locator('.fi-no-notification a:has-text("Download .csv")').waitFor({ timeout: 30_000 });

        // Initiate download
        const downloadPromise = page.waitForEvent('download', { timeout: 15_000 });
        await page.locator('.fi-no-notification a:has-text("Download .csv")').click();

        // Handle download
        const download = await downloadPromise;
        expect(download.suggestedFilename(), `Unknown extension for downloaded file: ${download.suggestedFilename()}`).match(/\.csv$/);
        await download.saveAs(path.join(options.exportDir, `${options.currentDate}.csv`));
    }, { date: options.currentDate });
})();
