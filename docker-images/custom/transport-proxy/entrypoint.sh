#!/bin/sh
set -euf

mkdir -p /homelab/.internal
printf 'starting\n' >/homelab/.internal/status.txt

if [ "$HOMELAB_ENV" = 'prod' ]; then
    delay="$(bash -c 'echo $((1 + RANDOM % 5))')"
    printf 'Delaying start for %ss\n' "$delay"
    sleep "$delay"
fi

respawn() {
    # shellcheck disable=SC2068
    (until $@; do
        printf 'Process "%s" crashed with exit code %s. Restarting...' "$@" "$?" >&2
        sleep 1
    done)
}

if [ "$HOMELAB_APP_TYPE" = 'actualbudget' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'changedetection' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'docker-cache-proxy' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'dozzle-server' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'gatus' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'glances' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'healthchecks' ]; then
    # TODO: Also forward email SMTP port?
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'homeassistant' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'homepage' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'jellyfin' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
    respawn socat TCP4-LISTEN:8096,fork,reuseaddr TCP4:app:8096 & # TODO: Remove this port after Let's Encrypt certificates
elif [ "$HOMELAB_APP_TYPE" = 'minio' ]; then
    if [ "$HOMELAB_CONTAINER_VARIANT" = 'api' ]; then
        respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy-api:80 &
        respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy-api:443 &
    elif [ "$HOMELAB_CONTAINER_VARIANT" = 'console' ]; then
        respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy-console:80 &
        respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy-console:443 &
    else
        printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}"
        exit 1
    fi
elif [ "$HOMELAB_APP_TYPE" = 'motioneye' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy-default:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy-default:443 &
    respawn socat TCP4-LISTEN:9081,fork,reuseaddr TCP4:http-proxy-stream:443 &
elif [ "$HOMELAB_APP_TYPE" = 'netalertx' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'ntfy' ]; then
    respawn socat TCP4-LISTEN:25,fork,reuseaddr TCP4:app:25 &
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'omada-controller' ]; then
    # HTTP/S ports
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy-admin:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy-admin:443 &
    # Reenable below for captive portal:
    # respawn socat TCP4-LISTEN:81,fork,reuseaddr TCP4:http-proxy-portal:80 &
    # respawn socat TCP4-LISTEN:444,fork,reuseaddr TCP4:http-proxy-portal:443 &

    # Other ports
    respawn socat -T5 UDP4-LISTEN:27001,fork,reuseaddr UDP4:app:27001 &
    respawn socat -T5 UDP4-LISTEN:29810,fork,reuseaddr UDP4:app:29810 &
    respawn socat TCP4-LISTEN:29811,fork,reuseaddr TCP4:app:29811 &
    respawn socat TCP4-LISTEN:29812,fork,reuseaddr TCP4:app:29812 &
    respawn socat TCP4-LISTEN:29813,fork,reuseaddr TCP4:app:29813 &
    respawn socat TCP4-LISTEN:29814,fork,reuseaddr TCP4:app:29814 &
    respawn socat TCP4-LISTEN:29815,fork,reuseaddr TCP4:app:29815 &
    respawn socat TCP4-LISTEN:29816,fork,reuseaddr TCP4:app:29816 &
elif [ "$HOMELAB_APP_TYPE" = 'openspeedtest' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'pihole' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
    respawn socat TCP4-LISTEN:53,fork,reuseaddr TCP4:app:53 &
    respawn socat -T5 UDP4-LISTEN:53,fork,reuseaddr UDP4:app:53 &
elif [ "$HOMELAB_APP_TYPE" = 'smb' ]; then
    respawn socat TCP4-LISTEN:139,fork,reuseaddr TCP4:app:139 &
    respawn socat TCP4-LISTEN:445,fork,reuseaddr TCP4:app:445 &
elif [ "$HOMELAB_APP_TYPE" = 'smtp4dev' ]; then
    respawn socat TCP4-LISTEN:25,fork,reuseaddr TCP4:app:25 &
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    # respawn socat TCP4-LISTEN:143,fork,reuseaddr TCP4:smtp4dev:143 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'speedtest-tracker' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'tvheadend' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
    respawn socat TCP4-LISTEN:9981,fork,reuseaddr TCP4:app:9981 & # TODO: Remove this port after Let's Encrypt certificates
    respawn socat TCP4-LISTEN:9982,fork,reuseaddr TCP4:app:9982 &
elif [ "$HOMELAB_APP_TYPE" = 'unifi-controller' ]; then
    # HTTP/S ports
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy-admin:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy-admin:443 &
    if [ "$HOMELAB_ENV" = 'prod' ]; then
        # In production we must also expose 8080, because unifi equipment depends on it
        respawn socat TCP4-LISTEN:8080,fork,reuseaddr TCP4:http-proxy-admin-raw:80 &
        respawn socat TCP4-LISTEN:8443,fork,reuseaddr TCP4:http-proxy-admin-raw:443 &
    fi
    # Reenable below for captive portal:
    # respawn socat TCP4-LISTEN:8843,fork,reuseaddr TCP4:app:8843 &
    # respawn socat TCP4-LISTEN:8880,fork,reuseaddr TCP4:app:8880 &

    # Other ports
    respawn socat -T5 UDP4-LISTEN:1900,fork,reuseaddr UDP4:app:1900 &
    respawn socat -T5 UDP4-LISTEN:3478,fork,reuseaddr UDP4:app:3478 &
    respawn socat -T5 UDP4-LISTEN:5514,fork,reuseaddr UDP4:app:5514 &
    respawn socat TCP4-LISTEN:6789,fork,reuseaddr TCP4:app:6789 &
    respawn socat -T5 UDP4-LISTEN:10001,fork,reuseaddr UDP4:app:10001 &
elif [ "$HOMELAB_APP_TYPE" = 'vaultwarden' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
elif [ "$HOMELAB_APP_TYPE" = 'vikunja' ]; then
    respawn socat TCP4-LISTEN:80,fork,reuseaddr TCP4:http-proxy:80 &
    respawn socat TCP4-LISTEN:443,fork,reuseaddr TCP4:http-proxy:443 &
else
    printf 'Unknown HOMELAB_APP_TYPE: %s\n' "${HOMELAB_APP_TYPE-N/A}" >&2
    exit 1
fi

printf 'started\n' >/homelab/.internal/status.txt
while true; do
    sleep infinity
    printf '"sleep infinity" somehow exited?' >&2
done
