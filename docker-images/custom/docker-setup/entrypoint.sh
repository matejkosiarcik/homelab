#!/bin/sh
set -euf

mkdir -p /homelab/.internal
printf 'starting\n' >/homelab/.internal/status.txt

# Wait for target container to start
timeout 30s sh <<EOF
while [ "$(docker ps --filter "name=^$HOMELAB_SETUP_TARGET_CONTAINER\$" | grep -c -- "$HOMELAB_SETUP_TARGET_CONTAINER" || true)" -eq '0' ]; do
    sleep 1
done
EOF

printf '%s - Starting setup\n' "$(date '+%Y-%m-%d_%H-%M-%S')"
docker exec "$HOMELAB_SETUP_TARGET_CONTAINER" sh /homelab/setup.sh
printf '%s - Finished setup\n' "$(date '+%Y-%m-%d_%H-%M-%S')"

printf 'started\n' >/homelab/.internal/status.txt
while true; do
    sleep infinity
    printf '"sleep infinity" somehow exited?' >&2
done
