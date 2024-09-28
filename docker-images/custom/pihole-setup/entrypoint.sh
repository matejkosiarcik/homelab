#!/bin/sh
set -euf

mkdir -p /homelab/.internal
printf 'starting\n' >/homelab/.internal/status.txt

docker exec "$HOMELAB_PIHOLE_CONTAINER" sh /homelab/setup.sh

printf 'started\n' >/homelab/.internal/status.txt
sleep infinity
