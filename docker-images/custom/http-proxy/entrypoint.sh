#!/bin/sh
set -euf

# Wait for certificates to exist before starting
timeout 30s sh <<EOF
while [ ! -e '/homelab/certs' ]; do
    sleep 1
done
while [ ! "$(find '/homelab/certs' -type f | grep . -c)" -gt 0 ]; do
    sleep 1
done
EOF

# Watch certificates in background
inotifywait --monitor --event modify --format '%w%f' --include 'certificate\.crt' '/homelab/certs' | xargs -n1 sh -c 'sleep 1 && printf "Detected new certificates\n" && apachectl -k restart' - &

printf '\n' >>/etc/apache2/envvars

# Set HOMELAB_ENV
if [ "${HOMELAB_ENV-x}" = 'x' ]; then
    printf 'HOMELAB_ENV unset\n' >&2
    exit 1
fi
export HOMELAB_ENV
printf "export HOMELAB_ENV='%s'\n" "$HOMELAB_ENV" >>/etc/apache2/envvars

# Set HOMELAB_APP_NAME
if [ "${HOMELAB_APP_NAME-x}" = 'x' ]; then
    printf 'HOMELAB_APP_NAME unset\n' >&2
    exit 1
fi
export HOMELAB_APP_NAME
printf "export HOMELAB_APP_NAME='%s'\n" "$HOMELAB_APP_NAME" >>/etc/apache2/envvars

# Set PROXY_UPSTREAM_URL
if [ "$HOMELAB_APP_NAME" = 'docker-cache-proxy' ]; then
    PROXY_UPSTREAM_URL="http://docker-registry"
elif [ "$HOMELAB_APP_NAME" = 'healthchecks' ]; then
    PROXY_UPSTREAM_URL="http://healthchecks:8000"
elif [ "$HOMELAB_APP_NAME" = 'home-assistant' ]; then
    PROXY_UPSTREAM_URL="http://home-assistant:8123"
elif [ "$HOMELAB_APP_NAME" = 'homer' ]; then
    PROXY_UPSTREAM_URL="http://homer"
elif [ "$HOMELAB_APP_NAME" = 'jellyfin' ]; then
    PROXY_UPSTREAM_URL="http://jellyfin:8096"
elif [ "$HOMELAB_APP_NAME" = 'lamp-controller' ]; then
    PROXY_UPSTREAM_URL="http://lamp-network-server"
elif [ "$HOMELAB_APP_NAME" = 'minio' ]; then
    if [ "$HOMELAB_CONTAINER_VARIANT" = 'api' ]; then
        PROXY_UPSTREAM_URL="http://minio:9000"
    elif [ "$HOMELAB_CONTAINER_VARIANT" = 'console' ]; then
        PROXY_UPSTREAM_URL="http://minio:9001"
    else
        printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}"
        exit 1
    fi
elif [ "$HOMELAB_APP_NAME" = 'omada-controller' ]; then
    if [ "$HOMELAB_ENV" = 'dev' ]; then
        if [ "$HOMELAB_CONTAINER_VARIANT" = 'admin' ]; then
            PROXY_UPSTREAM_URL="https://omada-controller:8443"
        elif [ "$HOMELAB_CONTAINER_VARIANT" = 'portal' ]; then
            PROXY_UPSTREAM_URL="https://omada-controller:8444"
        else
            printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}"
            exit 1
        fi
    elif [ "$HOMELAB_ENV" = 'prod' ]; then
        if [ "$HOMELAB_CONTAINER_VARIANT" = 'admin' ]; then
            PROXY_UPSTREAM_URL="https://omada-controller"
        elif [ "$HOMELAB_CONTAINER_VARIANT" = 'portal' ]; then
            PROXY_UPSTREAM_URL="https://omada-controller:444"
        else
            printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}"
            exit 1
        fi
    else
        printf 'Unknown HOMELAB_ENV: %s\n' "${HOMELAB_ENV-N/A}"
        exit 1
    fi
elif [ "$HOMELAB_APP_NAME" = 'pihole' ]; then
    PROXY_UPSTREAM_URL="http://pihole"
elif [ "$HOMELAB_APP_NAME" = 'smtp4dev' ]; then
    PROXY_UPSTREAM_URL="http://smtp4dev"
elif [ "$HOMELAB_APP_NAME" = 'speedtest-tracker' ]; then
    PROXY_UPSTREAM_URL="https://speedtest-tracker"
elif [ "$HOMELAB_APP_NAME" = 'tvheadend' ]; then
    PROXY_UPSTREAM_URL="http://tvheadend:9981"
elif [ "$HOMELAB_APP_NAME" = 'unifi-controller' ]; then
    if [ "$HOMELAB_ENV" = 'dev' ]; then
        if [ "$HOMELAB_CONTAINER_VARIANT" = 'admin' ]; then
            PROXY_UPSTREAM_URL="https://unifi-network-app:8443"
        elif [ "$HOMELAB_CONTAINER_VARIANT" = 'portal' ]; then
            PROXY_UPSTREAM_URL="https://unifi-network-app:8444"
        else
            printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}"
            exit 1
        fi
    elif [ "$HOMELAB_ENV" = 'prod' ]; then
        if [ "$HOMELAB_CONTAINER_VARIANT" = 'admin' ]; then
            PROXY_UPSTREAM_URL="https://unifi-network-app"
        elif [ "$HOMELAB_CONTAINER_VARIANT" = 'portal' ]; then
            PROXY_UPSTREAM_URL="https://unifi-network-app:444"
        else
            printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}"
            exit 1
        fi
    else
        printf 'Unknown HOMELAB_ENV" %s\n' "${HOMELAB_ENV-N/A}"
        exit 1
    fi
elif [ "$HOMELAB_APP_NAME" = 'uptime-kuma' ]; then
    PROXY_UPSTREAM_URL="http://uptime-kuma:3001"
else
    printf 'Unknown HOMELAB_APP_NAME: %s\n' "${HOMELAB_APP_NAME-N/A}"
    exit 1
fi
export PROXY_UPSTREAM_URL
printf "export PROXY_UPSTREAM_URL='%s'\n" "$PROXY_UPSTREAM_URL" >>/etc/apache2/envvars

# Set PROXY_UPSTREAM_URL_WS
PROXY_UPSTREAM_URL_WS="$(printf '%s' "$PROXY_UPSTREAM_URL" | sed 's~https:~wss:~;s~http:~ws:~')"
export PROXY_UPSTREAM_URL_WS
printf "export PROXY_UPSTREAM_URL_WS='%s'\n" "$PROXY_UPSTREAM_URL_WS" >>/etc/apache2/envvars

# Set PROXY_URL_REGEX_REVERSE
if [ "$HOMELAB_APP_NAME" = 'pihole' ]; then
    PROXY_URL_REGEX_REVERSE='^/(\.proxy(/.*)?)?$'
elif [ "$HOMELAB_APP_NAME" = 'unifi-controller' ] && [ "$HOMELAB_CONTAINER_VARIANT" = 'admin' ]; then
    PROXY_URL_REGEX_REVERSE='^/((\.proxy(/.*)?)|(setup/favicon.png))$'
else
    PROXY_URL_REGEX_REVERSE='^/\.proxy(/.*)?$'
fi
export PROXY_URL_REGEX_REVERSE
printf "export PROXY_URL_REGEX_REVERSE='%s'\n" "$PROXY_URL_REGEX_REVERSE" >>/etc/apache2/envvars

# Set PROXY_HTTPS_PORT
if [ "$HOMELAB_ENV" = 'prod' ]; then
    PROXY_HTTPS_PORT='443'
    if [ "$HOMELAB_APP_NAME" = 'omada-controller' ] || [ "$HOMELAB_APP_NAME" = 'unifi-controller' ]; then
        if [ "$HOMELAB_CONTAINER_VARIANT" = 'portal' ]; then
            PROXY_HTTPS_PORT='444'
        fi
    fi
elif [ "$HOMELAB_ENV" = 'dev' ]; then
    PROXY_HTTPS_PORT='8443'
    if [ "$HOMELAB_APP_NAME" = 'omada-controller' ] || [ "$HOMELAB_APP_NAME" = 'unifi-controller' ]; then
        if [ "$HOMELAB_CONTAINER_VARIANT" = 'portal' ]; then
            PROXY_HTTPS_PORT='8444'
        fi
    fi
else
    printf 'Unknown HOMELAB_ENV %s\n' "$HOMELAB_ENV" >&2
    exit 1
fi
export PROXY_HTTPS_PORT
printf "export PROXY_HTTPS_PORT='%s'\n" "$PROXY_HTTPS_PORT" >>/etc/apache2/envvars

# Start apache
apachectl -D FOREGROUND
