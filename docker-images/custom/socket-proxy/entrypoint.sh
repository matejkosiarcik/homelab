#!/bin/sh
set -euf

mkdir -p /homelab/.internal
printf 'starting\n' >/homelab/.internal/status.txt

if [ "$HOMELAB_APP_NAME" = 'docker-cache-proxy' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_NAME" = 'healthchecks' ]; then
    # TODO: Also forward email SMTP port?
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_NAME" = 'home-assistant' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_NAME" = 'homer' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_NAME" = 'lamp-controller' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_NAME" = 'omada-controller' ]; then
    # HTTP/S ports
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy-admin:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy-admin:443 &
    socat TCP4-LISTEN:81,fork,reuseaddr TCP4:http-proxy-portal:80 &
    socat TCP4-LISTEN:444,fork,reuseaddr TCP4:http-proxy-portal:443 &
    # Other ports
    socat -T5 UDP4-LISTEN:27001,fork,reuseaddr UDP4:main-app:27001 &
    socat -T5 UDP4-LISTEN:29810,fork,reuseaddr UDP4:main-app:29810 &
    socat TCP4-LISTEN:29811,fork,reuseaddr TCP4:main-app:29811 &
    socat TCP4-LISTEN:29812,fork,reuseaddr TCP4:main-app:29812 &
    socat TCP4-LISTEN:29813,fork,reuseaddr TCP4:main-app:29813 &
    socat TCP4-LISTEN:29814,fork,reuseaddr TCP4:main-app:29814 &
    socat TCP4-LISTEN:29815,fork,reuseaddr TCP4:main-app:29815 &
    socat TCP4-LISTEN:29816,fork,reuseaddr TCP4:main-app:29816 &
elif [ "$HOMELAB_APP_NAME" = 'pihole' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
    socat TCP4-LISTEN:53,fork,reuseaddr TCP4:main-app:53 &
    socat -T5 UDP4-LISTEN:53,fork,reuseaddr UDP4:main-app:53 &
elif [ "$HOMELAB_APP_NAME" = 'smtp4dev' ]; then
    socat TCP4-LISTEN:25,fork,reuseaddr TCP4:main-app:25 &
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    # socat TCP4-LISTEN:143,fork,reuseaddr TCP4:main-app:143 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_NAME" = 'speedtest-tracker' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_NAME" = 'unifi-controller' ]; then
    # HTTP/S ports
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy-admin:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy-admin:443 &
    socat TCP4-LISTEN:81,fork,reuseaddr TCP4:http-proxy-portal:80 &
    socat TCP4-LISTEN:444,fork,reuseaddr TCP4:http-proxy-portal:443 &
    # Other ports
    socat -T5 UDP4-LISTEN:1900,fork,reuseaddr UDP4:main-app:1900 &
    socat -T5 UDP4-LISTEN:3478,fork,reuseaddr UDP4:main-app:3478 &
    socat -T5 UDP4-LISTEN:5514,fork,reuseaddr UDP4:main-app:5514 &
    socat TCP4-LISTEN:6789,fork,reuseaddr TCP4:main-app:6789 &
    socat -T5 UDP4-LISTEN:10001,fork,reuseaddr UDP4:main-app:10001 &
elif [ "$HOMELAB_APP_NAME" = 'uptime-kuma' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
else
    printf 'Unknown HOMELAB_APP_NAME "%s"\n' "${HOMELAB_APP_NAME-N/A}" >&2
    exit 1
fi

printf 'started\n' >/homelab/.internal/status.txt
sleep infinity
