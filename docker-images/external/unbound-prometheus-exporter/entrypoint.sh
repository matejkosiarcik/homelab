#!/bin/sh
set -euf

timeout 30s sh <<EOF
while [ ! -e /homelab/sock/unbound.sock ]; do
    sleep 1
done
EOF

if [ ! -e /homelab/sock/unbound.sock ]; then
    printf '/homelab/sock/unbound.sock not found' >&2
    exit 1
fi

unbound_exporter -unbound.host unix:///homelab/sock/unbound.sock
