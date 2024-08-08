#!/bin/sh
set -euf

# Watch certificates in background
inotifywait --monitor --event modify --format '%w%f' --include 'certificate\.crt' '/certs' | xargs -n1 sh -c 'sleep 1 && printf "Detected new certificates\n" && apachectl -k restart' - &
# TODO: consider "ts '%Y-%m-%d %H:%M:%.S |'"

if [ "${HOMELAB_APP_TYPE-x}" = 'x' ]; then
    printf 'HOMELAB_APP_TYPE unset\n' >&2
    exit 1
fi
printf "\nexport HOMELAB_APP_TYPE='%s'\n" "$HOMELAB_APP_TYPE" >>/etc/apache2/envvars

HOMELAB_UPSTREAM_URL="http://main-app"
export HOMELAB_UPSTREAM_URL
printf "\nexport HOMELAB_UPSTREAM_URL='%s'\n" "$HOMELAB_UPSTREAM_URL" >>/etc/apache2/envvars

mkdir -p /log/access /log/error /log/forensic

# Start apache
apachectl -D FOREGROUND
