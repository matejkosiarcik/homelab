import fs from 'node:fs/promises';
import fsSync from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { expect } from 'chai';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import { getIsoDate, preprepare } from './.utils/utils.ts';
import { runAutomation } from './.utils/main.ts';

(async () => {
    preprepare();
    process.env['URL'] = 'https://speedtest-tracker.dev'; // TODO: Change to BASE_URL
    process.env['HOMELAB_APP_NAME'] = ''; // Must set this to work with web-automation utils

    let argumentParser = yargs(hideBin(process.argv))
        .locale('en')
        .option('output', {
            describe: 'Output file path',
            type: 'string',
            default: '-',
        });
    const args = await argumentParser.parse();

    const currentDate = getIsoDate();

    await runAutomation(async (page) => {
        page.setDefaultNavigationTimeout(15_000);
        page.setDefaultTimeout(2000);

        // Login
        await page.goto('/');
        await page.locator('input[type="text"][x-clipboard\\.raw]').waitFor({ timeout: 5000 });
        const text = await page.locator('input[type="text"][x-clipboard\\.raw]').inputValue();

        if (args.output === '-') {
            process.stdout.write(text);
        } else {
            await fs.writeFile(args.output, text);
        }
    }, { date: currentDate });
})();
