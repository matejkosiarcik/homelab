#!/bin/sh
set -euf

while [ "$(find /homelab/data -maxdepth 1 -type f -name 'system.xml' | wc -l)" -eq 0 ]; do
    sleep 1
done

sleep 5

cat '/homelab/data/system.xml' |
    sed 's~<EnableMetrics>false</EnableMetrics>~<EnableMetrics>true</EnableMetrics>~' |
    sponge '/homelab/data/system.xml'

if ! grep '<EnableMetrics>true</EnableMetrics>' <'/homelab/data/system.xml' >/dev/null; then
    printf 'Failed to enable metrics\n' >&2
    exit 1
fi
