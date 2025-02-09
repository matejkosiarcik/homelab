import nodeDns from 'node:dns/promises';
import _ from 'lodash';
import { expect, test } from '@playwright/test';
import { dnsLookup } from '../../../utils/utils';
import { apps } from '../../../utils/apps';
import { createTcpTest } from '../../../utils/tests';

test.describe(apps.unbound.title, () => {
    for (const instance of apps.unbound.instances) {
        test.describe(instance.title, () => {
            for (const dnsVariant of ['default', 'open'] as const) {
                createTcpTest(instance.url.replace(/\.(.+)$/, `-${dnsVariant}.$1`), 53, dnsVariant);
            }

            for (const transportVariant of ['tcp', 'udp'] as const) {
                for (const dnsVariant of ['default', 'open'] as const) {
                    for (const ipVariant of ['A', 'AAAA'] as const) {
                        test(`DNS: ${transportVariant.toUpperCase()} ${ipVariant} ${_.capitalize(dnsVariant)}`, async () => {
                            // Get domain for DNS server for a given variant
                            const unboundDnsDomain = instance.url.replace(/\.(.+)$/, `-${dnsVariant}.$1`);

                            // Get IP address
                            const unboundDnsIps = await nodeDns.resolve(unboundDnsDomain);
                            expect(unboundDnsIps, 'Pihole DNS address resolution').toHaveLength(1);

                            // Resolve external domain
                            const ips = await dnsLookup('example.com', transportVariant, ipVariant, unboundDnsIps[0]);
                            expect(ips, 'Domain should be resolved').not.toHaveLength(0);
                            expect(ips[0], `Resolved domain should be IPv${ipVariant === 'A' ? '4' : '6'}`).toMatch(ipVariant === 'A' ? /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ : /([0-9a-f]{1,4}:){7}[0-9a-f]{1,4}/);
                        });
                    }
                }
            }
        });
    }
});
