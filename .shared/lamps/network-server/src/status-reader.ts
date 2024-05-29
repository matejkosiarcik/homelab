import fs from 'fs';
import path from 'path';

export function setupStatusReader(dir: string) {
    const statusFile = path.join(dir, 'status.txt');

    if (!fs.existsSync(statusFile)) {
        fs.mkdirSync(path.dirname(statusFile), { recursive: true });
        fs.writeFileSync(statusFile, '', 'utf8');
    }

    fs.watch(statusFile, 'utf8', (event) => {
        if (event !== 'change') {
            return;
        }
        const content = fs.readFileSync(statusFile, 'utf8').trim();
        lastStatus = content === '1';
    });
}

export let lastStatus: boolean = false;
