#!/bin/sh
set -euf

# Wait for config file to be created (mostly relevant for initial setup)
while [ ! -e '/homelab/data/system.xml' ] || [ "$(wc -l <'/homelab/data/system.xml')" -eq 0 ]; do
    sleep 1
done

sleep "${HOMELAB_SETUP_DELAY-5}"

# Enable Prometheus metrics
sed 's~<EnableMetrics>false</EnableMetrics>~<EnableMetrics>true</EnableMetrics>~' <'/homelab/data/system.xml' | sponge '/homelab/data/system.xml'
if ! grep '<EnableMetrics>true</EnableMetrics>' <'/homelab/data/system.xml' >/dev/null; then
    printf 'Failed to enable metrics\n' >&2
    exit 1
fi
