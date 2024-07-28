#!/bin/sh
set -euf

if [ "${HOMELAB_APP_TYPE-x}" = 'pihole' ]; then
    if [ "${HOMELAB_APP_SUBTYPE-x}" = 'pihole-main' ]; then
        socat TCP4-LISTEN:80,fork,reuseaddr TCP4:pihole-main-http-proxy:80 &
        socat TCP4-LISTEN:443,fork,reuseaddr TCP4:pihole-main-http-proxy:443 &
        socat TCP4-LISTEN:53,fork,reuseaddr TCP4:pihole-main-app:53 &
        socat -T5 UDP4-LISTEN:53,fork,reuseaddr UDP4:pihole-main-app:53 &
    elif [ "${HOMELAB_APP_SUBTYPE-x}" = 'pihole-spouse' ]; then
        socat TCP4-LISTEN:80,fork,reuseaddr TCP4:pihole-spouse-http-proxy:80 &
        socat TCP4-LISTEN:443,fork,reuseaddr TCP4:pihole-spouse-http-proxy:443 &
        socat TCP4-LISTEN:53,fork,reuseaddr TCP4:pihole-spouse-app:53 &
        socat -T5 UDP4-LISTEN:53,fork,reuseaddr UDP4:pihole-spouse-app:53 &
    elif [ "${HOMELAB_APP_SUBTYPE-x}" = 'pihole-guest' ]; then
        socat TCP4-LISTEN:80,fork,reuseaddr TCP4:pihole-guest-http-proxy:80 &
        socat TCP4-LISTEN:443,fork,reuseaddr TCP4:pihole-guest-http-proxy:443 &
        socat TCP4-LISTEN:53,fork,reuseaddr TCP4:pihole-guest-app:53 &
        socat -T5 UDP4-LISTEN:53,fork,reuseaddr UDP4:pihole-guest-app:53 &
    else
        printf 'Unknown pihole variant "%s"\n' "${HOMELAB_APP_SUBTYPE-N/A}" >&2
        exit 1
    fi
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
