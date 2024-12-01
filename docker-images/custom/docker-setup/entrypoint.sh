#!/bin/sh
set -euf

mkdir -p /homelab/.internal
printf 'starting\n' >/homelab/.internal/status.txt

# Wait for target container to start
timeout 50s sh <<EOF
if [ "$(docker ps --quiet --filter "name=^$HOMELAB_SETUP_TARGET_CONTAINER\$" | wc -l)" -eq 1 ]; then
    printf 'Found container %s immediatelly\n' "$HOMELAB_SETUP_TARGET_CONTAINER" >&2
    return 0
fi
printf 'Waiting for container %s\n' "$HOMELAB_SETUP_TARGET_CONTAINER" >&2
while true; do
    if [ "$(docker ps --quiet --filter "name=^$HOMELAB_SETUP_TARGET_CONTAINER\$" | wc -l)" -eq 1 ]; then
        printf 'Found container %s in cycle\n' "$HOMELAB_SETUP_TARGET_CONTAINER" >&2
        break
        return 0
    fi
    printf 'Container %s in cycle not found\n' "$HOMELAB_SETUP_TARGET_CONTAINER" >&2
    printf 'Raw output:\n'
    docker ps --quiet --filter "name=^$HOMELAB_SETUP_TARGET_CONTAINER\$"
    docker ps --quiet --filter "name=^$HOMELAB_SETUP_TARGET_CONTAINER\$" | wc -l
    printf '.\n'
    sleep 1
done
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
