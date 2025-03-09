#!/bin/sh
set -euf

mkdir -p /homelab/.internal
printf 'starting\n' >/homelab/.internal/status.txt

sh /homelab/main.sh

printf 'started\n' >/homelab/.internal/status.txt
while true; do
    sleep infinity
    printf '"sleep infinity" somehow exited?' >&2
done
