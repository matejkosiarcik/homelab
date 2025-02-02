import fs from 'node:fs/promises';
import process from 'node:process';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';

(async () => {
    let argumentParser = yargs(hideBin(process.argv))
        .locale('en');
    const args = await argumentParser.parse();
    console.log(args);
})();
