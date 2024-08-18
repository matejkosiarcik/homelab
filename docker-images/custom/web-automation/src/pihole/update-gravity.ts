import { getBackupDir, getIsoDate, getTargetAdminPassword, loadEnv } from '../.utils/utils.ts';
import { runAutomation } from '../.utils/main.ts';

(async () => {
    loadEnv();

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
        await page.goto('/admin/gravity.php');

        // Update
        await page.locator('.alert-success').waitFor({ state: 'hidden' });
        await page.locator('button#gravityBtn:has-text("Update")').click();
        await page.locator('.alert-success').waitFor({ timeout: 15_000 });
    }, { date: currentDate });
})();
