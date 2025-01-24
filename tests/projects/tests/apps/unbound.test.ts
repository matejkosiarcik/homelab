import { expect, test } from '@playwright/test';
import { dnsLookup } from '../../../utils/utils';
import { apps } from '../../../utils/apps';
import _ from 'lodash';
import nodeDns from 'node:dns/promises';

test.describe(apps.unbound.title, () => {
    for (const instance of apps.unbound.instances) {

        test.describe(instance.title, () => {
            for (const transportVariant of ['tcp', 'udp'] as const) {
                for (const dnsVariant of ['default', 'open'] as const) {
                    test(`DNS: ${transportVariant.toUpperCase()} ${_.capitalize(dnsVariant)}`, async () => {
                        // Get domain for DNS server for a given variant
                        const unboundDnsDomain = instance.url.replace(/\.(.+)$/, `-${dnsVariant}.$1`);

                        // Get IP address
                        const unboundDnsIps = await nodeDns.resolve(unboundDnsDomain);
                        expect(unboundDnsIps, 'Pihole DNS address resolution').toHaveLength(1);

                        // Resolved external domain
                        const ips = await dnsLookup('example.com', transportVariant, 'A', unboundDnsIps[0]);
                        expect(ips, 'Domain should be resolved').not.toHaveLength(0);
                    });
                }
            }
        });
    }
});
