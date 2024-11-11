import fs from 'node:fs';
import path from 'node:path';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import dotenv from 'dotenv';
import { expressApp } from './express/express.ts';
import { initWinston, log } from './utils/logging.ts';

(async () => {
    let argumentParser = yargs(hideBin(process.argv))
        .locale('en')
        .help(true)
        .version(false)
        .option('help', {
            alias: 'h', describe: 'Show usage', type: 'boolean',
        })
        .option('verbose', {
            alias: 'v', describe: 'Verbose logging', type: 'boolean',
        })
        .option('quiet', {
            alias: 'q', describe: 'Less logging', type: 'boolean',
        });
    if (process.env['NOWRAP'] === '1') {
        argumentParser = argumentParser.wrap(null);
    }
    const args = await argumentParser.parse();

    if (fs.existsSync(path.join('.env'))) {
        dotenv.config({ path: path.join('.env') });
    }

    if (args.quiet && args.verbose) {
        console.error("Can't combine quiet and verbose");
        process.exit(1);
    }

    if (!process.env['LAMP_URL']) {
        throw new Error(`LAMP_URL unset`);
    }

    initWinston(args.quiet ? 'warning' : args.verbose ? 'debug' : 'info');

    const httpPort = process.env['HTTP_PORT'] || (fs.existsSync('/.dockerenv') ? '80' : '8080');
    log.debug(`HTTP port: ${httpPort}`);

    if (!process.env['HOMELAB_UPSTREAM_URL']) {
        process.env['HOMELAB_UPSTREAM_URL'] = (fs.existsSync('/.dockerenv') ? 'http://app-hardware-controller' : 'http://localhost:8081');
    }

    expressApp.listen(httpPort, () => {
        log.info(`Server started on port ${httpPort}`);
    });
})();
