#!/bin/sh
set -euf

service="${HOMELAB_SERVICE-x}"

if [ "$service" = 'pihole' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:pihole-http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:pihole-http-proxy:443 &
    socat TCP4-LISTEN:53,fork,reuseaddr TCP4:pihole-app:53 &
    socat -T5 UDP4-LISTEN:53,fork,reuseaddr UDP4:pihole-app:53 &
elif [ "$service" = 'smtp4dev' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:smtp4dev-http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:smtp4dev-http-proxy:443 &
    socat TCP4-LISTEN:25,fork,reuseaddr TCP4:smtp4dev-app:25 &
else
    printf 'Unknown service "%s"\n' "$service" >&2
    exit 1
fi
