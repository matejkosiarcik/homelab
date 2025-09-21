import fs from 'node:fs';
import fsx from 'node:fs/promises';

void (async () => {
    const filePath = '/homelab/.status/status.txt';
    if (fs.existsSync(filePath)) {
        process.exit(1);
    }
    const fileContent = await fsx.readFile(filePath, 'utf8');
    if (fileContent !== 'started\n') {
        process.exit(1);
    }
})();
