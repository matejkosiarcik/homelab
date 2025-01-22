import https from 'node:https';
import axios from 'axios';
import { expect, test } from '@playwright/test';
import { faker } from '@faker-js/faker';
import { getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';

test.describe(apps.pihole.title, () => {
    for (const instance of apps.pihole.instances) {
        const piholeKey = URL.parse(instance.url)!.hostname.replace(/\..*$/, '').replaceAll('-', '_').toUpperCase();

        test.describe(instance.title, () => {
            test('UI: Successful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/admin/login.php`);
                await page.locator('form#loginform input#loginpw').fill(getEnv(`${piholeKey}_PASSWORD`));
                await page.locator('form#loginform button[type=submit]').click();
                await page.waitForURL(/\/admin(?:\/?|\/index\.php)$/);
            });

            test('UI: Unsuccessful login', async ({ page }) => {
                await page.goto(instance.url);
                await page.waitForURL(`${instance.url}/admin/login.php`);
                await page.locator('form#loginform input#loginpw').fill(faker.string.alpha(10));
                await page.locator('form#loginform button[type=submit]').click();
                await page.waitForSelector('.login-box-msg.has-error >> text="Wrong password!"', { timeout: 10_000 });
                expect(page.url()).toStrictEqual(`${instance.url}/admin/login.php`);
            });

            test('API: HTTPS root', async () => {
                const response = await axios.get(instance.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });
        });
    }
});
