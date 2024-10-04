#!/bin/sh
set -euf

mkdir -p /homelab/.internal
printf 'starting\n' >/homelab/.internal/status.txt

sleep 15 # 10 seems not enough
printf '%s - Starting setup\n' "$(date '+%Y-%m-%d_%H-%M-%S')"
docker exec "$HOMELAB_PIHOLE_CONTAINER" sh /homelab/setup.sh
printf '%s - Finished setup\n' "$(date '+%Y-%m-%d_%H-%M-%S')"

printf 'started\n' >/homelab/.internal/status.txt
sleep infinity
