import process from 'node:process';
import dns from 'native-dns';

export function getEnv(instanceUrl: string, name: string): string {
    const instanceName = URL.parse(instanceUrl)!.hostname.replace(/\.home$/, '').replaceAll('-', '_');
    const envName = `${instanceName}_${name}`.toUpperCase();
    if (!(envName in process.env) || !process.env[envName]) {
        throw new Error(`Environment variable "${envName}" not set`);
    }
    return process.env[envName];
}

export async function dnsLookup(domain: string, transport: 'tcp' | 'udp', type: 'A' | 'AAAA', dnsServer: string): Promise<string[]> {
    return new Promise((resolve, reject) => {
        const returnData: string[] = [];
        const req = dns.Request({
            question: dns.Question({ name: domain, type: type, }),
            server: { address: dnsServer, port: 53, type: transport },
            timeout: 1000,
        });

        req.on('timeout', () => {
            reject(new Error('DNS Timeout'));
        });

        req.on('message', function (err: any, answer: { answer: { address: string }[] }) {
            if (err) {
                reject(new Error(`DNS Message error: ${err}`));
                return;
            }
            returnData.push(...answer.answer.map((entry) => entry.address));
        });

        req.on('end', function () {
            resolve(returnData.sort());
        });

        req.send();
    });
}
