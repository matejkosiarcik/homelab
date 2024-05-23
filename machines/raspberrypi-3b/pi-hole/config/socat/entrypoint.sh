#!/bin/sh
set -euf

rm -rf /app/.internal
mkdir -p /app/.internal
printf 'starting\n' >/app/.internal/status

socat TCP-LISTEN:80,fork TCP:pihole-http-proxy:80 &
socat TCP-LISTEN:443,fork TCP:pihole-http-proxy:443 &
socat TCP-LISTEN:53,fork TCP:pihole-app:53 &
socat UDP-LISTEN:53,fork UDP:pihole-app:53 &

printf 'started\n' >/app/.internal/status
sleep infinity
