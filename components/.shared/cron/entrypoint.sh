#!/bin/sh
set -euf

rm -rf /app/.internal
mkdir -p /app/.internal
printf 'starting\n' >/app/.internal/status

rm -f /log/cron.log
touch /log/cron.log

# Run script initially
CRON='0'
export CRON
touch /app/.internal/cron.env
if [ "${HOST-x}" != 'x' ]; then
    printf 'HOST=%s\n' "$HOST" >>/app/.internal/cron.env
fi
if [ "${ENV-x}" != 'x' ]; then
    printf 'ENV=%s\n' "$ENV" >>/app/.internal/cron.env
fi
if [ "${HOMELAB_SERVICE-x}" != 'x' ]; then
    printf 'HOMELAB_SERVICE=%s\n' "$HOMELAB_SERVICE" >>/app/.internal/cron.env
fi
sh /app/main.sh
printf 'CRON=1\n' "$CRON" >>/app/.internal/cron.env

# Run cron indefintely
crontab /app/crontab.cron
cron -L 15
printf 'started\n' >/app/.internal/status
tail -F /log/cron.log
