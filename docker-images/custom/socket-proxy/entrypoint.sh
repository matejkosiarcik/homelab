#!/bin/sh
set -euf

mkdir -p /homelab/.internal
printf 'starting\n' >/homelab/.internal/status.txt

if [ "$HOMELAB_APP_TYPE" = 'docker-cache-proxy' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'gatus' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'healthchecks' ]; then
    # TODO: Also forward email SMTP port?
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'home-assistant' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'homer' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'jellyfin' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
    socat TCP4-LISTEN:8096,fork,reuseaddr TCP4:jellyfin:8096 &
elif [ "$HOMELAB_APP_TYPE" = 'lamp-controller' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'minio' ]; then
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
elif [ "$HOMELAB_APP_TYPE" = 'omada-controller' ]; then
    # HTTP/S ports
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy-admin:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy-admin:443 &
    # Reenable below for captive portal:
    # socat TCP4-LISTEN:81,fork,reuseaddr TCP4:http-proxy-portal:80 &
    # socat TCP4-LISTEN:444,fork,reuseaddr TCP4:http-proxy-portal:443 &

    # Other ports
    socat -T5 UDP4-LISTEN:27001,fork,reuseaddr UDP4:omada-controller:27001 &
    socat -T5 UDP4-LISTEN:29810,fork,reuseaddr UDP4:omada-controller:29810 &
    socat TCP4-LISTEN:29811,fork,reuseaddr TCP4:omada-controller:29811 &
    socat TCP4-LISTEN:29812,fork,reuseaddr TCP4:omada-controller:29812 &
    socat TCP4-LISTEN:29813,fork,reuseaddr TCP4:omada-controller:29813 &
    socat TCP4-LISTEN:29814,fork,reuseaddr TCP4:omada-controller:29814 &
    socat TCP4-LISTEN:29815,fork,reuseaddr TCP4:omada-controller:29815 &
    socat TCP4-LISTEN:29816,fork,reuseaddr TCP4:omada-controller:29816 &
elif [ "$HOMELAB_APP_TYPE" = 'pihole' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
    socat TCP4-LISTEN:53,fork,reuseaddr TCP4:pihole:53 &
    socat -T5 UDP4-LISTEN:53,fork,reuseaddr UDP4:pihole:53 &
elif [ "$HOMELAB_APP_TYPE" = 'smb' ]; then
    socat TCP4-LISTEN:139,fork,reuseaddr TCP4:smb:139 &
    socat TCP4-LISTEN:445,fork,reuseaddr TCP4:smb:445 &
elif [ "$HOMELAB_APP_TYPE" = 'smtp4dev' ]; then
    socat TCP4-LISTEN:25,fork,reuseaddr TCP4:smtp4dev:25 &
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    # socat TCP4-LISTEN:143,fork,reuseaddr TCP4:smtp4dev:143 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'speedtest-tracker' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'tvheadend' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
    socat TCP4-LISTEN:9981,fork,reuseaddr TCP4:tvheadend:9981 &
    socat TCP4-LISTEN:9982,fork,reuseaddr TCP4:tvheadend:9982 &
elif [ "$HOMELAB_APP_TYPE" = 'unifi-controller' ]; then
    # HTTP/S ports
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy-admin:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy-admin:443 &
    if [ "$HOMELAB_ENV" = 'prod' ]; then
        # In production we must also expose 8080, because unifi equipment depends on it
        socat TCP4-LISTEN:8080,fork,reuseaddr TCP4:unifi-network-application:8080 &
        socat TCP4-LISTEN:8443,fork,reuseaddr TCP4:unifi-network-application:8443 &
    fi
    # Reenable below for captive portal:
    # socat TCP4-LISTEN:8843,fork,reuseaddr TCP4:unifi-network-application:8843 &
    # socat TCP4-LISTEN:8880,fork,reuseaddr TCP4:unifi-network-application:8880 &

    # Other ports
    socat -T10 UDP4-LISTEN:1900,fork,reuseaddr UDP4:unifi-network-application:1900 &
    socat -T10 UDP4-LISTEN:3478,fork,reuseaddr UDP4:unifi-network-application:3478 &
    socat -T10 UDP4-LISTEN:5514,fork,reuseaddr UDP4:unifi-network-application:5514 &
    socat TCP4-LISTEN:6789,fork,reuseaddr TCP4:unifi-network-application:6789 &
    socat -T10 UDP4-LISTEN:10001,fork,reuseaddr UDP4:unifi-network-application:10001 &
elif [ "$HOMELAB_APP_TYPE" = 'uptime-kuma' ]; then
    socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
else
    printf 'Unknown HOMELAB_APP_TYPE: %s\n' "${HOMELAB_APP_TYPE-N/A}" >&2
    exit 1
fi

printf 'started\n' >/homelab/.internal/status.txt
sleep infinity
