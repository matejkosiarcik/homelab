#!/bin/sh
set -euf

printf 'starting\n' >/homelab/tmpfs/status.txt

printf '%s - Starting setup\n' "$(date '+%Y-%m-%d_%H-%M-%S')"
sh /homelab/setup.sh
printf '%s - Finished setup\n' "$(date '+%Y-%m-%d_%H-%M-%S')"

printf 'started\n' >/homelab/tmpfs/status.txt
while true; do
    sleep infinity
    printf '"sleep infinity" somehow exited?' >&2
done
