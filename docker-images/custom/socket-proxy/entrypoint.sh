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
elif [ "$HOMELAB_APP_NAME" = 'jellyfin' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
    socat TCP4-LISTEN:8096,fork,reuseaddr TCP4:jellyfin:8096 &
elif [ "$HOMELAB_APP_NAME" = 'lamp-controller' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_NAME" = 'minio' ]; then
    if [ "$HOMELAB_CONTAINER_VARIANT" = 'api' ]; then
        socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy-api:80 &
        socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy-api:443 &
    elif [ "$HOMELAB_CONTAINER_VARIANT" = 'console' ]; then
        socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy-console:80 &
        socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy-console:443 &
    else
        printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}"
        exit 1
    fi
elif [ "$HOMELAB_APP_NAME" = 'omada-controller' ]; then
    # HTTP/S ports
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy-admin:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy-admin:443 &
    socat TCP4-LISTEN:81,fork,reuseaddr TCP4:http-proxy-portal:80 &
    socat TCP4-LISTEN:444,fork,reuseaddr TCP4:http-proxy-portal:443 &
    # Other ports
    socat -T5 UDP4-LISTEN:27001,fork,reuseaddr UDP4:omada-controller:27001 &
    socat -T5 UDP4-LISTEN:29810,fork,reuseaddr UDP4:omada-controller:29810 &
    socat TCP4-LISTEN:29811,fork,reuseaddr TCP4:omada-controller:29811 &
    socat TCP4-LISTEN:29812,fork,reuseaddr TCP4:omada-controller:29812 &
    socat TCP4-LISTEN:29813,fork,reuseaddr TCP4:omada-controller:29813 &
    socat TCP4-LISTEN:29814,fork,reuseaddr TCP4:omada-controller:29814 &
    socat TCP4-LISTEN:29815,fork,reuseaddr TCP4:omada-controller:29815 &
    socat TCP4-LISTEN:29816,fork,reuseaddr TCP4:omada-controller:29816 &
elif [ "$HOMELAB_APP_NAME" = 'pihole' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
    socat TCP4-LISTEN:53,fork,reuseaddr TCP4:pihole:53 &
    socat -T5 UDP4-LISTEN:53,fork,reuseaddr UDP4:pihole:53 &
elif [ "$HOMELAB_APP_NAME" = 'smb' ]; then
    socat TCP4-LISTEN:139,fork,reuseaddr TCP4:smb:139 &
    socat TCP4-LISTEN:445,fork,reuseaddr TCP4:smb:445 &
elif [ "$HOMELAB_APP_NAME" = 'smtp4dev' ]; then
    socat TCP4-LISTEN:25,fork,reuseaddr TCP4:smtp4dev:25 &
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    # socat TCP4-LISTEN:143,fork,reuseaddr TCP4:smtp4dev:143 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_NAME" = 'speedtest-tracker' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_NAME" = 'tvheadend' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
    socat TCP4-LISTEN:9981,fork,reuseaddr TCP4:tvheadend:9981 &
    socat TCP4-LISTEN:9982,fork,reuseaddr TCP4:tvheadend:9982 &
elif [ "$HOMELAB_APP_NAME" = 'unifi-controller' ]; then
    # HTTP/S ports
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy-admin:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy-admin:443 &
    socat TCP4-LISTEN:81,fork,reuseaddr TCP4:http-proxy-portal:80 &
    socat TCP4-LISTEN:444,fork,reuseaddr TCP4:http-proxy-portal:443 &
    # Other ports
    socat -T5 UDP4-LISTEN:1900,fork,reuseaddr UDP4:unifi-network-app:1900 &
    socat -T5 UDP4-LISTEN:3478,fork,reuseaddr UDP4:unifi-network-app:3478 &
    socat -T5 UDP4-LISTEN:5514,fork,reuseaddr UDP4:unifi-network-app:5514 &
    socat TCP4-LISTEN:6789,fork,reuseaddr TCP4:unifi-network-app:6789 &
    socat -T5 UDP4-LISTEN:10001,fork,reuseaddr UDP4:unifi-network-app:10001 &
elif [ "$HOMELAB_APP_NAME" = 'uptime-kuma' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
else
    printf 'Unknown HOMELAB_APP_NAME: %s\n' "${HOMELAB_APP_NAME-N/A}" >&2
    exit 1
fi

printf 'started\n' >/homelab/.internal/status.txt
sleep infinity
