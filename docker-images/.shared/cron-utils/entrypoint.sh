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
case "$HOMELAB_APP_TYPE" in
pihole)
    if [ "$HOMELAB_CONTAINER_TYPE" = 'web-automation' ]; then
        if [ "$HOMELAB_AUTOMATION_TYPE" = 'backup' ]; then
            cronfile='/app/crontab-backup.cron'
        else
            cronfile='/app/crontab-other.cron'
        fi
    else
        cronfile='/app/crontab.cron'
    fi
    ;;
*)
    cronfile='/app/crontab.cron'
    ;;
esac

supercronic "$cronfile"
