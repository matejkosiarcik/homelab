#!/bin/sh
set -euf

mkdir -p /homelab/.internal
printf 'starting\n' >/homelab/.internal/status.txt

# Wait for target container to start
timeout 45s sh <<EOF
if [ "$(docker ps --filter "name=^$HOMELAB_SETUP_TARGET_CONTAINER\$" --filter "status=running" | grep -c -- "$HOMELAB_SETUP_TARGET_CONTAINER" || true)" -eq '1' ]; then
    return 0
fi
printf 'Waiting for container %s\n' "$HOMELAB_SETUP_TARGET_CONTAINER" >&2
while [ "$(docker ps --filter "name=^$HOMELAB_SETUP_TARGET_CONTAINER\$" --filter "status=running" | grep -c -- "$HOMELAB_SETUP_TARGET_CONTAINER" || true)" -ne '1' ]; do
    sleep 1
done
printf 'Container found\n' >&2
sleep 1
EOF

sleep 10

printf '%s - Starting setup\n' "$(date '+%Y-%m-%d_%H-%M-%S')"
docker exec "$HOMELAB_SETUP_TARGET_CONTAINER" sh /homelab/setup.sh
printf '%s - Finished setup\n' "$(date '+%Y-%m-%d_%H-%M-%S')"

printf 'started\n' >/homelab/.internal/status.txt
while true; do
    sleep infinity
    printf '"sleep infinity" somehow exited?' >&2
done
