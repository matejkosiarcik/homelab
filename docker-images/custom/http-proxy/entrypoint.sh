#!/bin/sh
set -euf

# Watch certificates in background
inotifywait --monitor --event modify --format '%w%f' --include 'certificate\.crt' '/homelab/certs' | xargs -n1 sh -c 'sleep 1 && printf "Detected new certificates\n" && apachectl -k restart' - &

printf '\n' >>/etc/apache2/envvars

# Set HOMELAB_APP_NAME
if [ "${HOMELAB_APP_NAME-x}" = 'x' ]; then
    printf 'HOMELAB_APP_NAME unset\n' >&2
    exit 1
fi
export HOMELAB_APP_NAME
printf "export HOMELAB_APP_NAME='%s'\n" "$HOMELAB_APP_NAME" >>/etc/apache2/envvars

# Set PROXY_UPSTREAM_URL
if [ "${HOMELAB_APP_NAME-x}" = 'docker-cache-proxy' ]; then
    PROXY_UPSTREAM_URL="http://main-app"
elif [ "${HOMELAB_APP_NAME-x}" = 'healthchecks' ]; then
    PROXY_UPSTREAM_URL="http://main-app:8000"
elif [ "${HOMELAB_APP_NAME-x}" = 'home-assistant' ]; then
    PROXY_UPSTREAM_URL="http://main-app:8123"
elif [ "${HOMELAB_APP_NAME-x}" = 'lamp-controller' ]; then
    PROXY_UPSTREAM_URL="http://app-network-server"
elif [ "${HOMELAB_APP_NAME-x}" = 'omada-controller' ] || [ "${HOMELAB_APP_NAME-x}" = 'unifi-controller' ]; then
    if [ "$HOMELAB_ENV" = 'dev' ]; then
        if [ "$HOMELAB_CONTAINER_VARIANT" = 'admin' ]; then
            PROXY_UPSTREAM_URL="https://main-app:8443"
        elif [ "$HOMELAB_CONTAINER_VARIANT" = 'portal' ]; then
            PROXY_UPSTREAM_URL="https://main-app:8444"
        else
            printf 'Unknown HOMELAB_CONTAINER_VARIANT %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}"
            exit 1
        fi
    elif [ "$HOMELAB_ENV" = 'prod' ]; then
        if [ "$HOMELAB_CONTAINER_VARIANT" = 'admin' ]; then
            PROXY_UPSTREAM_URL="https://main-app"
        elif [ "$HOMELAB_CONTAINER_VARIANT" = 'portal' ]; then
            PROXY_UPSTREAM_URL="https://main-app:444"
        else
            printf 'Unknown HOMELAB_CONTAINER_VARIANT %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}"
            exit 1
        fi
    else
        printf 'Unknown HOMELAB_ENV %s\n' "${HOMELAB_ENV-N/A}"
        exit 1
    fi
elif [ "${HOMELAB_APP_NAME-x}" = 'speedtest-tracker' ]; then
    PROXY_UPSTREAM_URL="https://main-app"
elif [ "${HOMELAB_APP_NAME-x}" = 'uptime-kuma' ]; then
    PROXY_UPSTREAM_URL="http://main-app:3001"
else
    PROXY_UPSTREAM_URL="http://main-app"
fi
export PROXY_UPSTREAM_URL
printf "export PROXY_UPSTREAM_URL='%s'\n" "$PROXY_UPSTREAM_URL" >>/etc/apache2/envvars

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
