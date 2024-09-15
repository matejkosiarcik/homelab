#!/bin/sh
set -euf

mkdir -p /homelab/.internal
printf 'starting\n' >/homelab/.internal/status.txt

sh /homelab/main.sh

printf 'started\n' >/homelab/.internal/status.txt
sleep infinity
