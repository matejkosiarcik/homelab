import https from 'node:https';
import axios from 'axios';
import { expect, test } from '@playwright/test';
import { faker } from '@faker-js/faker';
import { getEnv } from '../../utils/utils';
import { apps } from '../../utils/instances';

test.describe('PiHole', () => {
    for (const pihole of apps.pihole) {
        const piholeKey = URL.parse(pihole.url)!.hostname.replace(/\..*$/, '').replaceAll('-', '_').toUpperCase();

        test.describe(pihole.title, () => {
            test('Successful login', async ({ page }) => {
                await page.goto(pihole.url);
                await page.waitForURL(`${pihole.url}/admin/login.php`);
                await page.locator('form#loginform input#loginpw').fill(getEnv(`${piholeKey}_PASSWORD`));
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

            test('Query Unsecure HTTP', async () => {
                const response = await axios.get(pihole.url.replace(/^https/, 'http'), { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, validateStatus: () => true });
                expect(response.status, 'Response Status').toStrictEqual(302);
                expect(response.headers['location'], 'Header Location').toStrictEqual(pihole.url);
            });

            test('Query Unsecure HTTP with random subpage', async () => {
                const subpage = `/${faker.string.alpha(10)}`;
                const response = await axios.get(`${pihole.url.replace(/^https/, 'http')}${subpage}`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, validateStatus: () => true });
                expect(response.status, 'Response Status').toStrictEqual(302);
                expect(response.headers['location'], 'Header Location').toStrictEqual(`${pihole.url}${subpage}`);
            });

            test('Query HTTPS', async () => {
                const response = await axios.get(pihole.url, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 999 });
                expect(response.status, 'Response Status').toStrictEqual(200);
            });
        });
    }
});
