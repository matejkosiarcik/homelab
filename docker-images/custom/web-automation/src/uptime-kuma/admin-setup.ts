import { getCredentials, getDir, getIsoDate, preprepare } from '../.utils/utils.ts';
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
        await page.goto('/');

        // Wait for either setup-form or login-form to load
        const setupButtonSelector = 'form button[type="submit"]:has-text("Create")';
        const loginButtonSelector = 'form button[type="submit"]:has-text("Login")';
        await page.locator(`${setupButtonSelector},${loginButtonSelector}`).waitFor({ timeout: 5000 });
        const isSetupForm = await page.locator(setupButtonSelector).isVisible({ timeout: 0 });
        if (!isSetupForm) {
            console.log('Skipping admin credentials (already setup)');
            return;
        }

        console.log('Setting up admin credentials');
        // Setup account
        await page.locator('form input[type="text"][placeholder="Username"]').fill(options.credentials.username);
        await page.locator('form input[type="password"][placeholder="Password"]').fill(options.credentials.password);
        await page.locator('form input[type="password"][placeholder="Repeat Password"]').fill(options.credentials.password);
        await page.locator(setupButtonSelector).click();

        // Wait for dashboard
        await page.waitForURL('/dashboard');
        await page.locator('ul.nav .nav-link .profile-pic').waitFor({ timeout: 10_000 });
    }, { date: options.currentDate });
})();
