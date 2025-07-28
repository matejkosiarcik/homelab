#!/bin/sh
set -euf

printf 'starting\n' >/homelab/.status/status.txt

sh /homelab/main.sh

printf 'started\n' >/homelab/.status/status.txt
while true; do
    sleep infinity
    printf '"sleep infinity" somehow exited?' >&2
done
