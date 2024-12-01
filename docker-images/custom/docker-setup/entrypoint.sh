#!/bin/sh
set -euf

mkdir -p /homelab/.internal
printf 'starting\n' >/homelab/.internal/status.txt

# if [ "$(docker ps --quiet --filter "name=^$HOMELAB_SETUP_TARGET_CONTAINER$")" != '' ]; then
#     printf 'Found container %s immediatelly\n' "$HOMELAB_SETUP_TARGET_CONTAINER" >&2
#     exit 0
# fi

# Wait for target container to start
timeout 50s sh <<EOF
printf 'Waiting for container %s\n' "$HOMELAB_SETUP_TARGET_CONTAINER" >&2
while [ "$(docker ps --quiet --filter "name=^$HOMELAB_SETUP_TARGET_CONTAINER$")" = '' ]; do
    printf 'Container %s in cycle not found\n' "$HOMELAB_SETUP_TARGET_CONTAINER" >&2
    sleep 1
done
printf 'Container %s found after cycle\n' "$HOMELAB_SETUP_TARGET_CONTAINER" >&2
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
