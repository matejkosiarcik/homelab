import fs from 'fs';
import path from 'path';
import { log } from './logging.ts';

let pipeFile: string | undefined;

export function setupStatusWriter(dir: string) {
    pipeFile = path.join(dir, 'commands.pipe');
}

export async function writeStatus(newStatus: boolean) {
    if (!pipeFile) {
        return;
    }

    if (!fs.existsSync(pipeFile)) {
        log.error('commands.pipe not found');
        return;
    }

    fs.writeFileSync(pipeFile, newStatus ? 'turn-on' : 'turn-off');
}
