import fs from 'fs/promises';
import legacyFs from 'fs';
import { getIsoDate, getTargetAdminPassword } from '../.utils/utils.ts';
import { runAutomation } from '../.utils/main.ts';
import path from 'path';

(async () => {
    const options = {
        currentDate: getIsoDate(),
        credentials: {
            password: getTargetAdminPassword(),
        },
    };

    await runAutomation(async (page) => {
        // Login
        await (async () => {
            await page.goto('/admin/login.php');
            await page.locator('form#loginform input#loginpw').fill(options.credentials.password);
            await page.locator('form#loginform button[type="submit"]').click({ noWaitAfter: true });
            await page.waitForURL('/admin/index.php');
        })();

        // Add custom blacklist/whitelist domains
        await (async () => {
            const domainTag = '[auto-setup]';
            while (true) {
                await page.goto('/admin/groups-domains.php');
                await page.locator('#domainsTable_filter input[type=search]').fill(domainTag);
                const removeButtonsCount = await page.locator('button[id^="deleteDomain_"]').count();
                if (removeButtonsCount === 0) {
                    break;
                }
                for (let i = 0; i < removeButtonsCount; i += 1) {
                    await page.locator('button[id^="deleteDomain_"]').first().click();
                    await page.locator('.alert-success').waitFor();
                    await page.locator('.alert-success').waitFor({ state: 'hidden', timeout: 10_000 });
                }
            }

            if (!legacyFs.existsSync('/.homelab/domains')) {
                return;
            }

            const domainsFiles = (await fs.readdir('/.homelab/domains', { recursive: false, withFileTypes: true }))
                .filter((el) => el.isFile())
                .filter((el) => /(blacklist|whitelist)/.test(el.name))
                .map((el) => path.join(el.parentPath, el.name));

            for (const file of domainsFiles) {
                const domains = (await fs.readFile(file, 'utf8'))
                    .split('\n')
                    .map((el) => el.replace(/#.*$/, ''))
                    .filter((el) => el.length > 0)
                    .map((el) => ({ domain: el.split(' ')[0], type: el.split(' ')[1].replace(/^\[(.*)\]$/, '$1') }))
                const isBlacklist = /blacklist/.test(path.basename(file));
                for (const domain of domains) {
                    const isWildcard = domain.type === 'wildcard';
                    await page.locator('input#new_domain').fill(domain.domain);
                    await page.locator('input#new_domain_comment').fill(domainTag);
                    if (isWildcard) {
                        await page.locator('label[for="wildcard_checkbox"]').click();
                    }
                    await page.locator(isBlacklist ? 'button#add2black' : 'button#add2white').click();
                }
            }
        })();

        // Update gravity
        await (async () => {
            await page.goto('/admin/gravity.php');

            // Perform update
            await page.locator('.alert-success').waitFor({ state: 'hidden' });
            await page.locator('button#gravityBtn:has-text("Update")').click();
            await page.locator('.alert-success').waitFor({ timeout: 15_000 });
        })();
    }, { date: options.currentDate });
})();
