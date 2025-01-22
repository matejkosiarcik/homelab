import https from 'node:https';
import axios from 'axios';
import { expect, test } from '@playwright/test';
import { faker } from '@faker-js/faker';
import { apps } from '../../utils/apps';

for (const app of Object.values(apps)) {
    test.describe(app.title, () => {
        for (const instance of app.instances) {
            test.describe(instance.title, () => {
                if (instance.url.startsWith('http')) {
                    test('API: Redirect HTTP to HTTPS (empty path)', async () => {
                        const response = await axios.get(instance.url.replace(/^https/, 'http'), { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, validateStatus: () => true });
                        expect(response.status, 'Response Status').toStrictEqual(302);
                        expect(response.headers['location'], 'Header Location').toStrictEqual(instance.url);
                    });

                    test('API: Redirect HTTP to HTTPS (root path)', async () => {
                        const response = await axios.get(`${instance.url.replace(/^https/, 'http')}/`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, validateStatus: () => true });
                        expect(response.status, 'Response Status').toStrictEqual(302);
                        expect(response.headers['location'], 'Header Location').toStrictEqual(instance.url);
                    });

                    test('API: Redirect HTTP to HTTPS (random subpage)', async () => {
                        const subpage = `/${faker.string.alpha(10)}`;
                        const response = await axios.get(`${instance.url.replace(/^https/, 'http')}${subpage}`, { httpsAgent: new https.Agent({ rejectUnauthorized: false }), maxRedirects: 0, validateStatus: () => true });
                        expect(response.status, 'Response Status').toStrictEqual(302);
                        expect(response.headers['location'], 'Header Location').toStrictEqual(`${instance.url}${subpage}`);
                    });
                }
            });
        }
    });
}
