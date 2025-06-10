import { faker } from '@faker-js/faker';
import { expect, test } from '@playwright/test';
import { axios, getEnv } from '../../utils/utils';
import { apps } from '../../utils/apps';
import { createApiRootTest, createFaviconTests, createHttpToHttpsRedirectTests, createPrometheusTests, createProxyTests, createTcpTests } from '../../utils/tests';

test.describe(apps['home-assistant'].title, () => {
    for (const instance of apps['home-assistant'].instances) {
        test.describe(instance.title, () => {
            createHttpToHttpsRedirectTests(instance.url);
            createProxyTests(instance.url);
            createPrometheusTests(instance.url, { auth: 'bearer', path: '/api/prometheus' });
            createApiRootTest(instance.url);
            createTcpTests(instance.url, [80, 443]);
            createFaviconTests(instance.url);

            test('API: Prometheus metrics content', async () => {
                const response = await axios.get(`${instance.url}/api/prometheus`, {
                    headers: {
                        Authorization: `Bearer ${getEnv(instance.url, 'PROMETHEUS_BEARER_TOKEN')}`,
                    },
                });
                expect(response.status, 'Response Status').toStrictEqual(200);
                const content = response.data as string;
                await test.info().attach('prometheus.txt', { contentType: 'text/plain', body: content });
                const lines = content.split('\n');
                const metrics = [
                    'homeassistant_binary_sensor_state',
                    'homeassistant_device_tracker_state',
                    'homeassistant_entity_available',
                    'homeassistant_last_updated_time_seconds',
                    'homeassistant_light_brightness_percent',
                    'homeassistant_person_state',
                    'homeassistant_sensor_battery_percent',
                    'homeassistant_sensor_state',
                    'homeassistant_sensor_timestamp_seconds',
                    'homeassistant_sensor_unit_floors',
                    'homeassistant_sensor_unit_m',
                    'homeassistant_sensor_unit_m_per_s',
                    'homeassistant_sensor_unit_steps',
                    'homeassistant_sensor_unit_u0x25u0x20available',
                    'homeassistant_state_change_created',
                    'homeassistant_state_change_total',
                    'python_info',
                ];
                for (const metric of metrics) {
                    expect(lines.find((el) => el.startsWith(metric)), `Metric ${metric}`).toBeDefined();
                }
            });

            const users = [
                {
                    username: 'admin',
                },
                {
                    username: 'homepage',
                },
                {
                    username: 'monika',
                },
                {
                    username: faker.string.alpha(10),
                    random: true,
                }
            ];
            for (const variant of users) {
                if (!variant.random) {
                    test(`UI: Successful login - User ${variant.username}`, async ({ page }) => {
                        await page.goto(instance.url);
                        await page.waitForURL(/\/auth\/authorize(?:\?.*)?$/);
                        await page.locator('input[name="username"]').waitFor({ timeout: 6000 });
                        await page.locator('input[name="username"]').fill(variant.username);
                        await page.locator('input[name="password"]').fill(getEnv(instance.url, `${variant.username}_PASSWORD`));
                        await page.locator('button#button').click();
                        await page.waitForURL(`${instance.url}/lovelace/0`);
                        await expect(page.locator('home-assistant')).toBeVisible();
                        await expect(page.locator('ha-sidebar')).toBeVisible();
                        await expect(page.locator('ha-panel-lovelace')).toBeVisible();
                    });
                }

                test(`UI: Unsuccessful login - ${variant.random ? 'Random user' : `User ${variant.username}`}`, async ({ page }) => {
                    await page.goto(instance.url);
                    await page.waitForURL(/\/auth\/authorize(?:\?.*)?$/);
                    const originalUrl = page.url();
                    await page.locator('input[name="username"]').waitFor({ timeout: 6000 });
                    await page.locator('input[name="username"]').fill(variant.username);
                    await page.locator('input[name="password"]').fill(faker.string.alpha(10));
                    await page.locator('button#button').click();
                    await expect(page.locator('ha-alert[alert-type="error"]:has-text("Invalid username or password")')).toBeVisible();
                    await expect(page, 'URL should not change').toHaveURL(originalUrl);
                });
            }
        });
    }
});
