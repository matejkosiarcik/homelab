#!/bin/sh
set -euf

rm -rf /app/.internal
mkdir -p /app/.internal
printf 'starting\n' >/app/.internal/status

rm -f /log/cron.log
touch /log/cron.log

# Setup Environment variables
CRON='0'
export CRON
printf 'HOMELAB_ENV=%s\n' "$HOMELAB_ENV" >>/app/.internal/cron.env
printf 'HOMELAB_APP_TYPE=%s\n' "$HOMELAB_APP_TYPE" >>/app/.internal/cron.env
printf 'HOMELAB_APP_EXTERNAL_DOMAIN=%s\n' "$HOMELAB_APP_EXTERNAL_DOMAIN" >>/app/.internal/cron.env

# Run script initially
sh /app/main.sh

# Run cron indefintely
printf 'CRON=1\n' "$CRON" >>/app/.internal/cron.env
crontab /app/crontab.cron
cron -L 15
printf 'started\n' >/app/.internal/status
tail -F /log/cron.log
