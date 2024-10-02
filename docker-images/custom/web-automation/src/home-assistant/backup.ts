import path from 'node:path';
import { expect } from 'chai';
import { getDir, getIsoDate, getCredentials, preprepare, retry } from '../.utils/utils.ts';
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
        // Login
        await page.goto('/');
        await page.waitForURL(/\/auth\/authorize/);
        await page.locator('form input[type="text"][name="username"]').fill(options.credentials.username);
        await page.locator('form input[type="password"][name="password"]').fill(options.credentials.password);
        const loginUrlPath = new URL(page.url()).pathname;
        await page.locator('form mwc-button button#button').click({ noWaitAfter: true });
        await page.waitForURL((url) => url.pathname !== loginUrlPath);

        // Go to backups and delete existing backups
        await page.goto('/config/backup');
        await page.locator('button[aria-label="Create backup"]').waitFor({ timeout: 10_000 });
        await page.locator('button[aria-label="Create backup"]').click();
        await page.locator('dialog-box ha-dialog[open] mwc-button[slot="primaryAction"] button').click();
        await page.locator('dialog-box ha-dialog[open]').waitFor({ state: 'hidden' });

        // Wait for new backup to appear
        await retry({
            action: async () => {
                const firstRowContent = await page.locator('ha-data-table .mdc-data-table__row >> nth=0').textContent();
                expect(firstRowContent?.toLowerCase()).includes('now');
            },
            delay: 1000,
            retries: 3,
        });

        // Initiate download
        const downloadPromise = page.waitForEvent('download', { timeout: 15_000 });
        await page.locator('ha-data-table .mdc-data-table__row mwc-icon-button[title="Download backup"] >> nth=0').click();

        // Handle download
        const download = await downloadPromise;
        expect(download.suggestedFilename(), `Unknown extension for downloaded file: ${download.suggestedFilename()}`).match(/\.tar$/);
        await download.saveAs(path.join(options.backupDir, `${options.currentDate}.tar`));

        // Remove backup from list
        const tableRowsCount = await page.locator('ha-data-table .mdc-data-table__content .mdc-data-table__row[role="row"]').count();
        for (let i = 0; i < tableRowsCount; i++) {
            await page.locator('ha-data-table .mdc-data-table__content .mdc-data-table__row[role="row"] mwc-icon-button[title="Delete backup"] >> nth=0').click();
            await page.locator('dialog-box ha-dialog[open] mwc-button[slot="primaryAction"] button').click();
            await page.locator('dialog-box ha-dialog[open]').waitFor({ state: 'hidden' });
            await retry({
                action: async () => {
                    const updatedCount = await page.locator('ha-data-table .mdc-data-table__content .mdc-data-table__row[role="row"]').count();
                    // NOTE: Math.max is because there is a single placeholder row if the table is empty
                    expect(updatedCount).eq(Math.max(tableRowsCount - i - 1, 1));
                },
                delay: 1000,
                retries: 2,
            });
        }
    }, { date: options.currentDate, skipInitial: true });
})();
