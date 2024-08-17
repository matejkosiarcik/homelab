#!/bin/sh
set -euf

# Watch certificates in background
inotifywait --monitor --event modify --format '%w%f' --include 'certificate\.crt' '/certs' | xargs -n1 sh -c 'sleep 1 && printf "Detected new certificates\n" && apachectl -k restart' - &

if [ "${HOMELAB_APP_TYPE-x}" = 'x' ]; then
    printf 'HOMELAB_APP_TYPE unset\n' >&2
    exit 1
fi
export HOMELAB_APP_TYPE
printf "\nexport HOMELAB_APP_TYPE='%s'\n" "$HOMELAB_APP_TYPE" >>/etc/apache2/envvars

if [ "${HOMELAB_APP_TYPE-x}" = 'lamp-controller' ]; then
    HOMELAB_UPSTREAM_URL="http://app-network-server"
elif [ "${HOMELAB_APP_TYPE-x}" = 'healthchecks' ]; then
    HOMELAB_UPSTREAM_URL="http://main-app:8000"
elif [ "${HOMELAB_APP_TYPE-x}" = 'omada-controller' ]; then
    if [ "${HOMELAB_ENV-x}" = dev ]; then
        HOMELAB_UPSTREAM_URL="http://main-app:8080"
    else
        HOMELAB_UPSTREAM_URL="http://main-app"
    fi
elif [ "${HOMELAB_APP_TYPE-x}" = 'uptime-kuma' ]; then
    HOMELAB_UPSTREAM_URL="http://main-app:3001"
else
    HOMELAB_UPSTREAM_URL="http://main-app"
fi
export HOMELAB_UPSTREAM_URL
printf "\nexport HOMELAB_UPSTREAM_URL='%s'\n" "$HOMELAB_UPSTREAM_URL" >>/etc/apache2/envvars

mkdir -p /log/access /log/error /log/forensic

# Start apache
apachectl -D FOREGROUND
