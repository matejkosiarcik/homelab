#!/bin/sh
set -euf

if [ "${HOMELAB_APP_TYPE-x}" = 'pihole' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
    socat TCP4-LISTEN:53,fork,reuseaddr TCP4:main-app:53 &
    socat -T5 UDP4-LISTEN:53,fork,reuseaddr UDP4:main-app:53 &
elif [ "${HOMELAB_APP_TYPE-x}" = 'smtp4dev' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:smtp4dev-http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:smtp4dev-http-proxy:443 &
    socat TCP4-LISTEN:25,fork,reuseaddr TCP4:smtp4dev-app:25 &
elif [ "${HOMELAB_APP_TYPE-x}" = 'homer' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:homer-http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:homer-http-proxy:443 &
elif [ "${HOMELAB_APP_TYPE-x}" = 'lamp-controller' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:lamp-controller-http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:lamp-controller-http-proxy:443 &
else
    printf 'Unknown app type "%s"\n' "${HOMELAB_APP_TYPE-N/A}" >&2
    exit 1
fi
