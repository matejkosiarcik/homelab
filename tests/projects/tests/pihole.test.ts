import { expect, test } from '@playwright/test';
import { faker } from '@faker-js/faker';
import { getEnv } from '../../utils/utils';

test.describe('PiHole', () => {
    const piholeInstances = [
        { url: 'https://pihole-1-primary.home', key: '', title: 'Primary 1' },
        { url: 'https://pihole-1-secondary.home', key: '', title: 'Secondary 1' },
        { url: 'https://pihole-2-primary.home', key: '', title: 'Primary 2' },
        { url: 'https://pihole-2-secondary.home', key: '', title: 'Secondary 2' },
    ];
    for (const pihole of piholeInstances) {
        test.describe(pihole.title, () => {
            test('Successful login', async ({ page }) => {
                await page.goto(pihole.url);
                await page.waitForURL(`${pihole.url}/admin/login.php`);
                await page.locator('form#loginform input#loginpw').fill(getEnv(`${pihole.key}_PASSWORD`));
                await page.locator('form#loginform button[type=submit]').click();
                await page.waitForURL(/\/admin(?:\/?|\/index\.php)$/);
            });

            test('Unsuccessful login', async ({ page }) => {
                await page.goto(pihole.url);
                await page.waitForURL(`${pihole.url}/admin/login.php`);
                await page.locator('form#loginform input#loginpw').fill(faker.string.alpha(10));
                await page.locator('form#loginform button[type=submit]').click();
                await page.waitForSelector('.login-box-msg.has-error >> text="Wrong password!"', { timeout: 10_000 });
                expect(page.url()).toStrictEqual(`${pihole.url}/admin/login.php`);
            });
        });
    }
});
