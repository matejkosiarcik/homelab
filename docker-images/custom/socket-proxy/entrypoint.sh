#!/bin/sh
set -euf

mkdir -p /app/.internal
printf 'starting\n' >/app/.internal/status

if [ "$HOMELAB_APP_TYPE" = 'healthchecks' ]; then
    # TODO: Also forward email SMTP port?
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'homer' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'lamp-controller' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'omada-controller' ]; then
    # HTTP/S ports
    if [ "$HOMELAB_ENV" = 'prod' ]; then
        socat TCP4-LISTEN:80,fork,reuseaddr TCP4:main-app:80 &
        socat TCP4-LISTEN:443,fork,reuseaddr TCP4:main-app:443 &
        socat TCP4-LISTEN:81,fork,reuseaddr TCP4:main-app:81 &
        socat TCP4-LISTEN:444,fork,reuseaddr TCP4:main-app:444 &
    elif [ "$HOMELAB_ENV" = 'dev' ]; then
        socat TCP4-LISTEN:8080,fork,reuseaddr TCP4:main-app:8080 &
        socat TCP4-LISTEN:8443,fork,reuseaddr TCP4:main-app:8443 &
        socat TCP4-LISTEN:8081,fork,reuseaddr TCP4:main-app:8081 &
        socat TCP4-LISTEN:8444,fork,reuseaddr TCP4:main-app:8444 &
    fi
    # Other ports
    socat -T5 UDP4-LISTEN:27001,fork,reuseaddr UDP4:main-app:27001 &
    socat -T5 UDP4-LISTEN:29810,fork,reuseaddr UDP4:main-app:29810 &
    socat TCP4-LISTEN:29811,fork,reuseaddr TCP4:main-app:29811 &
    socat TCP4-LISTEN:29812,fork,reuseaddr TCP4:main-app:29812 &
    socat TCP4-LISTEN:29813,fork,reuseaddr TCP4:main-app:29813 &
    socat TCP4-LISTEN:29814,fork,reuseaddr TCP4:main-app:29814 &
    socat TCP4-LISTEN:29815,fork,reuseaddr TCP4:main-app:29815 &
    socat TCP4-LISTEN:29816,fork,reuseaddr TCP4:main-app:29816 &
elif [ "$HOMELAB_APP_TYPE" = 'pihole' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
    socat TCP4-LISTEN:53,fork,reuseaddr TCP4:main-app:53 &
    socat -T5 UDP4-LISTEN:53,fork,reuseaddr UDP4:main-app:53 &
elif [ "$HOMELAB_APP_TYPE" = 'smtp4dev' ]; then
    socat TCP4-LISTEN:25,fork,reuseaddr TCP4:main-app:25 &
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    # socat TCP4-LISTEN:143,fork,reuseaddr TCP4:main-app:143 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'unifi-controller' ]; then
    # HTTP/S ports
    if [ "$HOMELAB_ENV" = 'prod' ]; then
        socat TCP4-LISTEN:80,fork,reuseaddr TCP4:main-app:80 &
        socat TCP4-LISTEN:443,fork,reuseaddr TCP4:main-app:443 &
        socat TCP4-LISTEN:81,fork,reuseaddr TCP4:main-app:81 &
        socat TCP4-LISTEN:444,fork,reuseaddr TCP4:main-app:444 &
    elif [ "$HOMELAB_ENV" = 'dev' ]; then
        socat TCP4-LISTEN:8080,fork,reuseaddr TCP4:main-app:8080 &
        socat TCP4-LISTEN:8443,fork,reuseaddr TCP4:main-app:8443 &
        socat TCP4-LISTEN:8081,fork,reuseaddr TCP4:main-app:8081 &
        socat TCP4-LISTEN:8444,fork,reuseaddr TCP4:main-app:8444 &
    fi
    # Other ports
    socat -T5 UDP4-LISTEN:1900,fork,reuseaddr UDP4:main-app:1900 &
    socat -T5 UDP4-LISTEN:3478,fork,reuseaddr UDP4:main-app:3478 &
    socat -T5 UDP4-LISTEN:5514,fork,reuseaddr UDP4:main-app:5514 &
    socat TCP4-LISTEN:6789,fork,reuseaddr TCP4:main-app:6789 &
    socat -T5 UDP4-LISTEN:10001,fork,reuseaddr UDP4:main-app:10001 &
elif [ "$HOMELAB_APP_TYPE" = 'uptime-kuma' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
else
    printf 'Unknown app type "%s"\n' "${HOMELAB_APP_TYPE-N/A}" >&2
    exit 1
fi

printf 'started\n' >/app/.internal/status
sleep infinity
