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

# Set HOMELAB_APP_TYPE
if [ "${HOMELAB_APP_TYPE-x}" = 'x' ]; then
    printf 'HOMELAB_APP_TYPE unset\n' >&2
    exit 1
fi
export HOMELAB_APP_TYPE
printf "export HOMELAB_APP_TYPE='%s'\n" "$HOMELAB_APP_TYPE" >>/etc/apache2/envvars

# Set HOMELAB_APP_EXTERNAL_DOMAIN
if [ "${HOMELAB_APP_EXTERNAL_DOMAIN-x}" = 'x' ]; then
    printf 'HOMELAB_APP_EXTERNAL_DOMAIN unset\n' >&2
    exit 1
fi
export HOMELAB_APP_EXTERNAL_DOMAIN
printf "export HOMELAB_APP_EXTERNAL_DOMAIN='%s'\n" "$HOMELAB_APP_EXTERNAL_DOMAIN" >>/etc/apache2/envvars

# Set PROXY_UPSTREAM_URL
if [ "$HOMELAB_APP_TYPE" = 'changedetection' ]; then
    PROXY_UPSTREAM_URL="http://changedetection:5000"
elif [ "$HOMELAB_APP_TYPE" = 'docker-cache-proxy' ]; then
    PROXY_UPSTREAM_URL="http://docker-registry"
elif [ "$HOMELAB_APP_TYPE" = 'gatus' ]; then
    PROXY_UPSTREAM_URL="http://gatus:8080"
elif [ "$HOMELAB_APP_TYPE" = 'healthchecks' ]; then
    PROXY_UPSTREAM_URL="http://healthchecks:8000"
elif [ "$HOMELAB_APP_TYPE" = 'home-assistant' ]; then
    PROXY_UPSTREAM_URL="http://home-assistant:8123"
elif [ "$HOMELAB_APP_TYPE" = 'homepage' ]; then
    PROXY_UPSTREAM_URL="http://homepage:3000"
elif [ "$HOMELAB_APP_TYPE" = 'homer' ]; then
    PROXY_UPSTREAM_URL="http://homer"
elif [ "$HOMELAB_APP_TYPE" = 'jellyfin' ]; then
    PROXY_UPSTREAM_URL="http://jellyfin:8096"
elif [ "$HOMELAB_APP_TYPE" = 'lamp-controller' ]; then
    PROXY_UPSTREAM_URL="http://lamp-network-server"
elif [ "$HOMELAB_APP_TYPE" = 'minio' ]; then
    if [ "$HOMELAB_CONTAINER_VARIANT" = 'api' ]; then
        PROXY_UPSTREAM_URL="http://minio:9000"
    elif [ "$HOMELAB_CONTAINER_VARIANT" = 'console' ]; then
        PROXY_UPSTREAM_URL="http://minio:9001"
    else
        printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}"
        exit 1
    fi
elif [ "$HOMELAB_APP_TYPE" = 'ntfy' ]; then
    PROXY_UPSTREAM_URL="http://ntfy"
elif [ "$HOMELAB_APP_TYPE" = 'omada-controller' ]; then
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
elif [ "$HOMELAB_APP_TYPE" = 'pihole' ]; then
    PROXY_UPSTREAM_URL="http://pihole"
elif [ "$HOMELAB_APP_TYPE" = 'smtp4dev' ]; then
    PROXY_UPSTREAM_URL="http://smtp4dev"
elif [ "$HOMELAB_APP_TYPE" = 'speedtest-tracker' ]; then
    PROXY_UPSTREAM_URL="https://speedtest-tracker"
elif [ "$HOMELAB_APP_TYPE" = 'tvheadend' ]; then
    PROXY_UPSTREAM_URL="http://tvheadend:9981"
elif [ "$HOMELAB_APP_TYPE" = 'unifi-controller' ]; then
    if [ "$HOMELAB_CONTAINER_VARIANT" = 'admin' ] || [ "$HOMELAB_CONTAINER_VARIANT" = 'admin-raw-secure' ]; then
        PROXY_UPSTREAM_URL="https://unifi-network-application:8443"
    elif [ "$HOMELAB_CONTAINER_VARIANT" = 'admin-raw-insecure' ]; then
        PROXY_UPSTREAM_URL="http://unifi-network-application:8080"
    elif [ "$HOMELAB_CONTAINER_VARIANT" = 'portal' ]; then
        PROXY_UPSTREAM_URL="https://unifi-network-application:8444"
    else
        printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}"
        exit 1
    fi
elif [ "$HOMELAB_APP_TYPE" = 'uptime-kuma' ]; then
    PROXY_UPSTREAM_URL="http://uptime-kuma:3001"
else
    printf 'Unknown HOMELAB_APP_TYPE: %s\n' "${HOMELAB_APP_TYPE-N/A}"
    exit 1
fi
export PROXY_UPSTREAM_URL
printf "export PROXY_UPSTREAM_URL='%s'\n" "$PROXY_UPSTREAM_URL" >>/etc/apache2/envvars

# Set PROXY_UPSTREAM_URL_WS
PROXY_UPSTREAM_URL_WS="$(printf '%s' "$PROXY_UPSTREAM_URL" | sed 's~https:~wss:~;s~http:~ws:~')"
export PROXY_UPSTREAM_URL_WS
printf "export PROXY_UPSTREAM_URL_WS='%s'\n" "$PROXY_UPSTREAM_URL_WS" >>/etc/apache2/envvars

# Set PROXY_HTTP_PORT
if [ "$HOMELAB_ENV" = 'prod' ]; then
    PROXY_HTTP_PORT='80'
elif [ "$HOMELAB_ENV" = 'dev' ]; then
    PROXY_HTTP_PORT='8080'
else
    printf 'Unknown HOMELAB_ENV %s\n' "$HOMELAB_ENV" >&2
    exit 1
fi
export PROXY_HTTP_PORT
printf "export PROXY_HTTP_PORT='%s'\n" "$PROXY_HTTP_PORT" >>/etc/apache2/envvars

# Set PROXY_HTTPS_PORT
if [ "$HOMELAB_ENV" = 'prod' ]; then
    PROXY_HTTPS_PORT='443'
    if [ "$HOMELAB_APP_TYPE" = 'omada-controller' ] || [ "$HOMELAB_APP_TYPE" = 'unifi-controller' ]; then
        if [ "$HOMELAB_CONTAINER_VARIANT" = 'portal' ]; then
            PROXY_HTTPS_PORT='444'
        fi
    fi
elif [ "$HOMELAB_ENV" = 'dev' ]; then
    PROXY_HTTPS_PORT='8443'
    if [ "$HOMELAB_APP_TYPE" = 'omada-controller' ] || [ "$HOMELAB_APP_TYPE" = 'unifi-controller' ]; then
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

# Set PROXY_FORCE_HTTPS
if [ "$HOMELAB_APP_TYPE" = 'ntfy' ]; then
    PROXY_FORCE_HTTPS='false'
elif [ "$HOMELAB_APP_TYPE" = 'unifi-controller' ] && [ "$HOMELAB_CONTAINER_VARIANT" = 'admin-raw-insecure' ]; then
    PROXY_FORCE_HTTPS='false'
else
    PROXY_FORCE_HTTPS='true'
fi
export PROXY_FORCE_HTTPS
printf "export PROXY_FORCE_HTTPS='%s'\n" "$PROXY_FORCE_HTTPS" >>/etc/apache2/envvars

# Start apache
apachectl -D FOREGROUND
