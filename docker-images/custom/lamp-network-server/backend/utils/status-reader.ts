import fs from 'node:fs';
import path from 'node:path';

export function setupStatusReader(file: string) {
    if (!fs.existsSync(file)) {
        fs.mkdirSync(path.dirname(file), { recursive: true });
        fs.writeFileSync(file, '', 'utf8');
    }

    fs.watch(file, 'utf8', (event) => {
        if (event !== 'change') {
            return;
        }
        const content = fs.readFileSync(file, 'utf8').trim();
        lastStatus = content === '1';
    });
}

export let lastStatus: boolean = false;
