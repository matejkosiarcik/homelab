import process from 'node:process';

export function getEnv(name: string): string {
    if (!(name in process.env) || !process.env[name]) {
        throw new Error(`Environment variable "${name}" not set`);
    }
    return process.env[name];
}
