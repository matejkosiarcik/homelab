import fs from 'node:fs/promises';
import process from 'node:process';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import { chromium } from 'playwright';

(async () => {
    let argumentParser = yargs(hideBin(process.argv))
        .locale('en')
        .option('output', {
            describe: 'Output file path',
            type: 'string',
            default: '-',
        });
    const args = await argumentParser.parse();

    const outputValue = await (async () => {
        const browser = await chromium.launch({ headless: true });
        try {
            const page = await browser.newPage({ baseURL: 'https://speedtest-tracker.dev' });
            try {
                page.setDefaultNavigationTimeout(15_000);
                page.setDefaultTimeout(2000);
                await page.goto('/');
                await page.locator('input[type="text"][x-clipboard\\.raw]').waitFor({ timeout: 5000 });
                return await page.locator('input[type="text"][x-clipboard\\.raw]').inputValue();
            } finally {
                await page.close();
            }
        } finally {
            await browser.close();
        }
    })();

    if (args.output === '-') {
        process.stdout.write(`${outputValue}\n`);
    } else {
        await fs.writeFile(args.output, outputValue);
    }
})();
