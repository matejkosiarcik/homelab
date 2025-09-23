#!/bin/sh
set -euf

printf 'starting\n' >/homelab/.status/status.txt

# Setup Environment variables
CRON='0'
export CRON

# Run script initially
if [ "${HOMELAB_CRON_SKIP_INITIAL-}" != '1' ]; then
    sh /homelab/cron-wrapper.sh
fi

# Run cron indefinitely
CRON=1
printf 'started\n' >/homelab/.status/status.txt

# Determine cronfile
cronfile=''
if [ "$HOMELAB_CONTAINER_NAME" = 'web-automation' ]; then
    cronfile="/homelab/crontab-$HOMELAB_APP_TYPE-$HOMELAB_CONTAINER_VARIANT.cron"
else
    cronfile='/homelab/crontab.cron'
fi

if [ ! -e "$cronfile" ]; then
    printf 'crontab file %s not found\n' "$cronfile"
    exit 1
fi

# Prepare Graceful shutdown
trap 'exit 0' TERM

# Start HTTP server
if [ -e '/homelab/server/dist/main.js' ]; then
    node /homelab/server/dist/main.js &
    node_pid="$!"
fi

# Start cron
supercronic "$cronfile" &
supercronic_pid="$!"

# Wait for subprocesses
wait "$supercronic_pid"
if [ "${node_pid-x}" != x ]; then
    wait "$node_pid"
fi
