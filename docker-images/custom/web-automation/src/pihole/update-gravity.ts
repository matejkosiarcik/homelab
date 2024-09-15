import { getCredentials, getIsoDate, preprepare } from '../.utils/utils.ts';
import { runAutomation } from '../.utils/main.ts';

(async () => {
    preprepare();

    const options = {
        currentDate: getIsoDate(),
        credentials: {
            password: getCredentials('password'),
        },
    };

    await runAutomation(async (page) => {
        // Login
        await page.goto('/admin/login.php');
        await page.locator('form#loginform input#loginpw').fill(options.credentials.password);
        await page.locator('form#loginform button[type="submit"]').click({ noWaitAfter: true });
        await page.waitForURL('/admin/index.php');

        // Update gravity
        await page.goto('/admin/gravity.php');
        await page.locator('.alert-success').waitFor({ state: 'hidden' });
        await page.locator('button#gravityBtn:has-text("Update")').click();
        await page.locator('.alert-success').waitFor({ timeout: 15_000 });
    }, { date: options.currentDate });
})();
