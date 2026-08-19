import fs from 'node:fs';
import fsx from 'node:fs/promises';
import path from 'node:path';
import axios from 'axios';
import dotenv from 'dotenv';
import { assert } from 'simple-assert';
import parseDuration from 'parse-duration-ms';
import sleep from 'sleep-promise';

type InputHealthcheck = {
    grace: string,
    name: string,
    schedule: string,
    slug: string,
    tz: string,
};

type Healthcheck = {
    grace: number,
    name: string,
    schedule: string,
    slug: string,
    tz: string,
    uuid: string,
};

async function loadHealthchecks(file: string): Promise<Healthcheck[]> {
    const fileContent = await fsx.readFile(file, 'utf8');
    const inputHealthchecks = JSON.parse(fileContent) as { healthchecks: InputHealthcheck[] };
    const outputHealthchecks = inputHealthchecks.healthchecks.map((healthcheck) => ({
        grace: parseDuration(healthcheck.grace)! / 1000,
        name: healthcheck.name,
        schedule: healthcheck.schedule,
        slug: healthcheck.slug,
        tz: healthcheck.tz,
        uuid: '',
    }));

    return outputHealthchecks;
}

(async () => {
    const statusFile = path.join('tmpfs', 'status.txt');
    await fsx.mkdir(path.dirname(statusFile), { recursive: true });
    await fsx.writeFile(statusFile, 'starting', 'utf8');

    if (fs.existsSync('.secrets.env')) {
        dotenv.config({ path: '.secrets.env', quiet: true });
    }

    axios.defaults.headers.common['X-Api-Key'] = process.env['HEALTHCHECKS_API_KEY'] || '';
    axios.defaults.baseURL = 'http://app:8000/api/v3/status'; // 'https://healthchecks.matejhome.com/api/v3'
    axios.defaults.validateStatus = () => true;

    const startDate = new Date();
    while (true) {
        const currentDate = new Date();
        const elapsedSeconds = (currentDate.getTime() - startDate.getTime()) / 1000;
        if (elapsedSeconds > 60) {
            throw new Error("Couldn't connect to healthcheck-app in reasonable time.");
        }

        try {
            const response = await axios.get('/');
            assert(response.status === 200, `Failed to connect to healthcheck-app\nStatus: ${response.status}\n`);
            break;
        } catch {
            await sleep(1000);
        }
    }

    // Load new healthchecks
    const declaredHealthchecks = await loadHealthchecks('healthchecks.json');

    // Load existing healthchecks in database
    const existingHealthchecks = await (async () => {
        const response = await axios.get('/checks');
        assert(response.status === 200, `Failed to fetch list of healthchecks\nStatus: ${response.status}\nBody: ${response.data}`);
        const body = response.data as { checks: Healthcheck[] };
        return body.checks;
    })();

    // Delete healthchecks in database which are no longer used
    const healthchecksToDelete = existingHealthchecks.filter((el1) => !declaredHealthchecks.find((el2) => el2.slug === el1.slug));
    for (const healthcheck of healthchecksToDelete) {
        console.log(`Deleting healthcheck ${healthcheck.slug}`);
        await (async () => {
            const response = await axios.delete(`/checks/${healthcheck.uuid}`);
            assert(response.status === 200, `Failed to delete healthcheck\nStatus: ${response.status}\nBody: ${response.data}`);
        })();
    }

    // Edit existing healthchecks in database
    const healthchecksToEdit = existingHealthchecks.filter((el1) => declaredHealthchecks.find((el2) => el2.slug === el1.slug));
    for (const healthcheck of healthchecksToEdit) {
        const declaredHealthcheck = declaredHealthchecks.find((el) => el.slug === healthcheck.slug)!;
        if (declaredHealthcheck.schedule !== healthcheck.schedule || declaredHealthcheck.grace !== healthcheck.grace || declaredHealthcheck.name !== healthcheck.name || declaredHealthcheck.tz !== healthcheck.tz) {
            await (async () => {
                console.log(`Updating healthcheck ${healthcheck.slug}`);
                const response = await axios.post(`/checks/${healthcheck.uuid}`, healthcheck);
                assert(response.status === 200, `Failed to update healthcheck\nStatus: ${response.status}\nBody: ${response.data}`);
            })();
        } else {
            console.log(`Healthcheck ${healthcheck.slug} already up-to-date.`);
        }
    }

    // Add new healthchecks to database
    const healthchecksToAdd = declaredHealthchecks.filter((el1) => !existingHealthchecks.find((el2) => el2.slug === el1.slug));
    for (const healthcheck of healthchecksToAdd) {
        await (async () => {
            console.log(`Creating healthcheck ${healthcheck.slug}`);
            const response = await axios.post('/checks/', healthcheck, {
                headers: {
                    'Content-Type': 'application/json',
                },
            });
            assert(response.status === 201, `Failed to create healthcheck\nStatus: ${response.status}\nBody: ${response.data}`);
        })();
    }

    await fsx.writeFile(statusFile, 'started', 'utf8');
})();
