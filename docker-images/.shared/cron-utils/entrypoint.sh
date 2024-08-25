#!/bin/sh
set -euf

mkdir -p /app/.internal
printf 'starting\n' >/app/.internal/status

# Setup Environment variables
CRON='0'
export CRON

# Run script initially
sh /app/main.sh

# Run cron indefinitely
CRON=1
printf 'started\n' >/app/.internal/status

# Determine cronfile
cronfile=""
if [ "$HOMELAB_CONTAINER_NAME" = 'web-automation' ]; then
    if [ "$HOMELAB_CONTAINER_VARIANT" = 'backup' ]; then
        cronfile='/app/crontab-backup.cron'
    else
        cronfile='/app/crontab-other.cron'
    fi
else
    cronfile='/app/crontab.cron'
fi

supercronic "$cronfile"
