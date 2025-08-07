#!/bin/sh
set -euf

if [ ! -e /homelab/sock/unbound.sock ]; then
    touch /homelab/sock/unbound.sock
fi

if [ ! -e /homelab/logs/unbound.log ]; then
    touch /homelab/logs/unbound.log
    chmod 0666 /homelab/logs/unbound.log
fi

configfile='/homelab/config'
if [ "$HOMELAB_ENV" = dev ]; then
    configfile="$configfile/unbound-dev.conf"
else
    configfile="$configfile/$HOMELAB_APP_NAME.conf"
fi

if [ ! -e "$configfile" ]; then
    printf 'Config file %s not found\n' "$configfile" >&2
    exit 1
fi

unbound -v -d -c "$configfile"
