import { getIsoDate, getTargetAdminPassword } from '../.utils/utils.ts';
import { runAutomation } from '../.utils/main.ts';

(async () => {
    const credentials = {
        password: getTargetAdminPassword(),
    };
    const options = {
        date: getIsoDate(),
    };

    await runAutomation(async (page) => {
        // Login
        await page.goto('/admin/login.php');
        await page.locator('form#loginform input#loginpw').fill(credentials.password);
        await page.locator('form#loginform button[type="submit"]').click({ noWaitAfter: true });
        await page.waitForURL('/admin/index.php');

        // Wait for menu to load
        const disableBlockingButtonSelector = '.main-sidebar #pihole-disable';
        const enableBlockingButtonSelector = '.main-sidebar #pihole-enable';
        await Promise.any(
            (await page.locator(`${enableBlockingButtonSelector},${disableBlockingButtonSelector}`).all())
                .map(async (locator) => locator.waitFor())
        );

        // Check current blocking status
        const currentMode = await page.locator(disableBlockingButtonSelector).isVisible() ? 'blocking' : 'not-blocking';
        const targetMode = (process.env['HOMELAB_BLOCK_ADS'] || '1') === '1' ? 'blocking' : 'not-blocking';
        if (currentMode === targetMode) {
            console.log(`PiHole is already ${targetMode} ads`);
            return;
        }

        // Flip blocking if currently misconfigured
        switch (targetMode) {
            case 'blocking': {
                await page.locator(enableBlockingButtonSelector).click();
                await page.locator(disableBlockingButtonSelector).waitFor();
                break;
            }
            case 'not-blocking': {
                await page.locator(disableBlockingButtonSelector).click();
                await page.locator('.main-sidebar #pihole-disable-indefinitely').click();
                await page.locator(enableBlockingButtonSelector).waitFor();
                break;
            }
        }
    }, options);
})();
