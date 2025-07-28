#!/bin/sh
set -euf

mkdir -p /homelab/.status
printf 'starting\n' >/homelab/.status/status.txt

printf '%s - Starting setup\n' "$(date '+%Y-%m-%d_%H-%M-%S')"
sh /homelab/setup.sh
printf '%s - Finished setup\n' "$(date '+%Y-%m-%d_%H-%M-%S')"

printf 'started\n' >/homelab/.status/status.txt
while true; do
    sleep infinity
    printf '"sleep infinity" somehow exited?' >&2
done
