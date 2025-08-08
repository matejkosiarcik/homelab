import fs from 'node:fs';
import axios from 'axios';
import dotenv from 'dotenv';
import { assert } from 'simple-assert';

type Healthcheck = {
    grace: number,
    name: string,
    schedule: string,
    slug: string,
    tz: string,
    uuid: string,
};

const existingHealthecks: Healthcheck[] = [];
const createdHealthchecks: Partial<Healthcheck>[] = [];

async function addHealthcheck(healthcheck: Healthcheck): Promise<void> {
    const newHealthcheck: Partial<Healthcheck> = {
        slug: healthcheck.slug,
        name: healthcheck.name,
        schedule: healthcheck.schedule,
        grace: 1800, // 30 minutes
        tz: 'Europe/Bratislava',
    };

    const existingHealtheck = existingHealthecks.find((el) => el.slug === newHealthcheck.slug);
    if (existingHealtheck) {
        if (existingHealtheck.schedule !== newHealthcheck.schedule || existingHealtheck.grace !== newHealthcheck.grace || existingHealtheck.name !== newHealthcheck.name || existingHealtheck.tz !== newHealthcheck.tz) {
            await (async () => {
                console.log(`Updating healthcheck ${newHealthcheck.slug}`);
                const response = await axios.post(`/checks/${existingHealtheck.uuid}`, newHealthcheck);
                assert(response.status === 200, `Failed to update healthcheck\nStatus: ${response.status}\nBody: ${JSON.stringify(response.data)}`);
            })();
        }
        createdHealthchecks.push(newHealthcheck);
        return;
    }

    await (async () => {
        console.log(`Creating healthcheck ${newHealthcheck.slug}`);
        const response = await axios.post('/checks/', newHealthcheck, {
            headers: {
                'Content-Type': 'application/json',
            },
        });
        assert(response.status === 201, `Failed to create healthcheck\nStatus: ${response.status}\nBody: ${JSON.stringify(response.data)}`);
    })();
    createdHealthchecks.push(newHealthcheck);
}

(async () => {
    if (fs.existsSync('.secrets.env')) {
        dotenv.config({ path: '.secrets.env', quiet: true });
    }

    axios.defaults.headers.common['X-Api-Key'] = process.env['HEALTHCHECKS_API_KEY'] || '';
    axios.defaults.baseURL = 'https://healthchecks.matejhome.com/api/v3';
    axios.defaults.validateStatus = () => true;

    await (async () => {
        const response = await axios.get('/checks');
        assert(response.status === 200, `Failed to fetch list of healthchecks\nStatus: ${response.status}\nBody: ${JSON.stringify(response.data)}`);
        const body = response.data as { checks: Healthcheck[] };
        existingHealthecks.push(...body.checks);
    })();

    const otherHealthchecks = [
        {
            name: 'Certbot - App',
            cron: '30 00 * * *',
        },
        {
            name: 'Renovatebot - App',
            cron: '00 01 * * *',
        },
        {
            name: 'Speedtest Tracker - App',
            cron: '15 */4 * * *',
        },
    ];
    for (const healthcheck of otherHealthchecks) {
        const slug = healthcheck.name.toLocaleLowerCase().replaceAll(' ', '-').replaceAll(/\-+/g, '-');
        await addHealthcheck({ slug: slug, schedule: healthcheck.cron, name: healthcheck.name, uuid: '', grace: 0, tz: '', });
    }

    const deployHealthchecks = [
        'Odroid H3',
        'Odroid H4 Ultra',
        'MacBook Pro 2012',
        'Raspberry Pi 3B',
        'Raspberry Pi 4B 2GB',
        'Raspberry Pi 4B 4GB',
    ];
    for (const _name of deployHealthchecks) {
        const name = `${_name} - Deploy`;
        const slug = name.toLocaleLowerCase().replaceAll(/[ \[\]]/g, '-').replaceAll(/\-+/g, '-').replace(/-+$/, '').replace(/^-+/, '');
        await addHealthcheck({ slug: slug, schedule: '00 00 * * *', name: name, uuid: '', grace: 0, tz: '', }); // TODO: Set time
    }

    const updateHealthchecks = [
        'Odroid H3',
        'Odroid H4 Ultra',
        'MacBook Pro 2012',
        'Raspberry Pi 3B',
        'Raspberry Pi 4B 2GB',
        'Raspberry Pi 4B 4GB',
    ];
    for (const _name of updateHealthchecks) {
        const name = `${_name} - Update`;
        const slug = name.toLocaleLowerCase().replaceAll(/[ \[\]]/g, '-').replaceAll(/\-+/g, '-').replace(/-+$/, '').replace(/^-+/, '');
        await addHealthcheck({ slug: slug, schedule: '00 00 * * *', name: name, uuid: '', grace: 0, tz: '', }); // TODO: Set time
    }

    const certificatorHealthchecks = [
        'ActualBudget',
        'ChangeDetection',
        'Docker Cache Proxy - DockerHub',
        'Docker Stats - MacBook Pro 2012',
        'Docker Stats - Odroid H3',
        'Docker Stats - Odroid H4 Ultra',
        'Docker Stats - Raspberry Pi 3B',
        'Docker Stats - Raspberry Pi 4B 2GB',
        'Docker Stats - Raspberry Pi 4B 4GB',
        'Dozzle',
        'Gatus - 1',
        'Gatus - 2',
        'Glances - MacBook Pro 2012',
        'Glances - Odroid H3',
        'Glances - Odroid H4 Ultra',
        'Glances - Raspberry Pi 3B',
        'Glances - Raspberry Pi 4B 2GB',
        'Glances - Raspberry Pi 4B 4GB',
        'Gotify',
        'Grafana',
        'Healthchecks',
        'Home Assistant',
        'Homepage',
        'Jellyfin',
        'Kiwix - Wikipedia',
        'Kiwix - Wiktionary',
        'Minio',
        'MotionEye - Kitchen',
        'Netalertx',
        'Node Exporter - MacBook Pro 2012',
        'Node Exporter - Odroid H3',
        'Node Exporter - Odroid H4 Ultra',
        'Node Exporter - Raspberry Pi 3B',
        'Node Exporter - Raspberry Pi 4B 2GB',
        'Node Exporter - Raspberry Pi 4B 4GB',
        'Ntfy',
        'Ollama',
        'Ollama [private]',
        'Omada Controller',
        'Open WebUI',
        'Open WebUI [private]',
        'Openspeedtest',
        'Owntracks',
        'PiHole - 1 Primary',
        'PiHole - 1 Secondary',
        'PiHole - 2 Primary',
        'PiHole - 2 Secondary',
        'Prometheus',
        'Smtp4dev',
        'Speedtest Tracker',
        'Tvheadend',
        'Unbound - 1 Default',
        'Unbound - 1 Open',
        'Unbound - 2 Default',
        'Unbound - 2 Open',
        'Unifi Controller',
        'Uptime Kuma',
        'Vaultwarden',
        'Vikunja',
    ];
    for (const _name of certificatorHealthchecks) {
        const name = `${_name} - Certificator`;
        const slug = name.toLocaleLowerCase().replaceAll(/[ \[\]]/g, '-').replaceAll(/\-+/g, '-').replace(/-+$/, '').replace(/^-+/, '');
        await addHealthcheck({ slug: slug, schedule: '30 01 * * *', name: name, uuid: '', grace: 0, tz: '', });
    }

    for (const healthcheck of existingHealthecks) {
        if (!createdHealthchecks.find((el) => el.slug === healthcheck.slug)) {
            console.log(`Deleting healthcheck ${healthcheck.slug}`);
            await (async () => {
                const response = await axios.delete(`/checks/${healthcheck.uuid}`);
                assert(response.status === 200, `Failed to delete healthcheck\nStatus: ${response.status}\nBody: ${JSON.stringify(response.data)}`);
            })();
        }
    }
})();
