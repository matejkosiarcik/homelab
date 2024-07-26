#!/bin/sh
set -euf

if [ "${HOMELAB_SERVICE-x}" = 'pihole' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:pihole-http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:pihole-http-proxy:443 &
    socat TCP4-LISTEN:53,fork,reuseaddr TCP4:pihole-app:53 &
    socat -T5 UDP4-LISTEN:53,fork,reuseaddr UDP4:pihole-app:53 &
elif [ "${HOMELAB_SERVICE-x}" = 'pihole2' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:pihole2-http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:pihole2-http-proxy:443 &
    socat TCP4-LISTEN:53,fork,reuseaddr TCP4:pihole2-app:53 &
    socat -T5 UDP4-LISTEN:53,fork,reuseaddr UDP4:pihole2-app:53 &
elif [ "${HOMELAB_SERVICE-x}" = 'smtp4dev' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:smtp4dev-http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:smtp4dev-http-proxy:443 &
    socat TCP4-LISTEN:25,fork,reuseaddr TCP4:smtp4dev-app:25 &
elif [ "${HOMELAB_SERVICE-x}" = 'homer' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:homer-http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:homer-http-proxy:443 &
elif [ "${HOMELAB_SERVICE-x}" = 'lamp-controller' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:lamp-controller-http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:lamp-controller-http-proxy:443 &
else
    printf 'Unknown service "%s"\n' "${HOMELAB_SERVICE-UNKNOWN}" >&2
    exit 1
fi
