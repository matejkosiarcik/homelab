#!/bin/sh
set -euf

mkdir -p /homelab/.internal
printf 'starting\n' >/homelab/.internal/status.txt

# Setup Environment variables
CRON='0'
export CRON

# Run script initially
timeout 5m sh /homelab/main.sh

# Run cron indefinitely
CRON=1
printf 'started\n' >/homelab/.internal/status.txt

# Determine cronfile
cronfile=""
if [ "$HOMELAB_CONTAINER_NAME" = 'web-automation' ]; then
    if [ "$HOMELAB_CONTAINER_VARIANT" = 'backup' ]; then
        cronfile='/homelab/crontab-backup.cron'
    else
        cronfile='/homelab/crontab-other.cron'
    fi
else
    cronfile='/homelab/crontab.cron'
fi

supercronic "$cronfile"
