import fs from 'node:fs/promises';
import process from 'node:process';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import { getIsoDate, preprepare } from './.utils/utils.ts';
import { runAutomation } from './.utils/main.ts';

(async () => {
    preprepare();
    process.env['URL'] = 'https://speedtest-tracker.dev';
    process.env['HOMELAB_APP_NAME'] = ''; // Must set this to work with web-automation utils

    let argumentParser = yargs(hideBin(process.argv))
        .locale('en')
        .option('output', {
            describe: 'Output file path',
            type: 'string',
            default: '-',
        });
    const args = await argumentParser.parse();

    const outputValue = await (async () => {
        if (process.env['HOMELAB_SPEEDTEST_TRACKER_APP_KEY']) {
            return process.env['HOMELAB_SPEEDTEST_TRACKER_APP_KEY']!;
        }

        const currentDate = getIsoDate();
        return await runAutomation(async (page) => {
            page.setDefaultNavigationTimeout(15_000);
            page.setDefaultTimeout(2000);

            // Login
            await page.goto('/');
            await page.locator('input[type="text"][x-clipboard\\.raw]').waitFor({ timeout: 5000 });
            const text = await page.locator('input[type="text"][x-clipboard\\.raw]').inputValue();
            return text;
        }, { date: currentDate });
    })();

    if (args.output === '-') {
        process.stdout.write(outputValue);
    } else {
        await fs.writeFile(args.output, outputValue);
    }
})();
