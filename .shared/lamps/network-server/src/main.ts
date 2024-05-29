import fs from 'fs';
import path from 'path';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import dotenv from 'dotenv';
import { initWinston, log } from './logging.ts';
import { expressApp } from './express.ts';
import { setupStatusWatcher } from './status-watch.ts';

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
        })
        .option('status-dir', {
            describe: 'Status directory path', type: 'string',
        })
        .option('http-port', {
            describe: 'HTTP port for webui (default: "8080" or HTTP_PORT env variable)', type: 'string',
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

    initWinston(args.quiet ? 'warning' : args.verbose ? 'debug' : 'info');

    const statusDir = args.statusDir || process.env['STATUS_DIR'] || 'status';
    const httpPort = args.httpPort || process.env['HTTP_PORT'] || (fs.existsSync('/.dockerenv') ? '80' : '8080');

    log.debug(`Status dir: ${statusDir}`);
    log.debug(`HTTP port: ${httpPort}`);

    setupStatusWatcher(statusDir);

    expressApp.listen(httpPort, () => {
        log.info(`Server started on port ${httpPort}`);
    });
})();
