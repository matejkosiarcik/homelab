#!/bin/sh
set -euf

printf 'starting\n' >/homelab/tmpfs/status.txt

sh /homelab/main.sh

printf 'started\n' >/homelab/tmpfs/status.txt
while true; do
    sleep infinity
    printf '"sleep infinity" somehow exited?' >&2
done
