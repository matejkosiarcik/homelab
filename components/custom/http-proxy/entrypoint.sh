#!/bin/sh
set -euf

# Create log directories
mkdir -p /log/access /log/error /log/forensic

# Watch certificates in background
inotifywait --monitor --event modify --format '%w%f' --include 'certificate\.crt' '/certs' | xargs -n1 sh -c 'sleep 1 && printf "Detected new certificates\n" && apachectl -k restart' - &
# TODO: consider "ts '%Y-%m-%d %H:%M:%.S |'"

if [ "${HOMELAB_APP_TYPE-x}" = 'x' ]; then
    printf 'HOMELAB_APP_TYPE unset\n' >&2
    exit 1
fi
if [ "${HOMELAB_APP_SUBTYPE-x}" = 'x' ]; then
    printf 'HOMELAB_APP_SUBTYPE unset\n' >&2
    exit 1
fi

HOMELAB_UPSTREAM_URL="http://${HOMELAB_APP_SUBTYPE}-app"
export HOMELAB_UPSTREAM_URL

# Start apache
apachectl -D FOREGROUND
