#!/bin/sh
set -euf

rm -rf /app/.internal
mkdir -p /app/.internal
printf 'starting\n' >/app/.internal/status

if [ -e '/log/cron.log' ]; then
    rm -f /log/cron.log
fi
touch /log/cron.log

# Run script initially
CRON='0'
export CRON
printf 'HOST=%s\n' "$HOST" >>/app/.internal/cron.env
printf 'ENV=%s\n' "$ENV" >>/app/.internal/cron.env
sh /app/main.sh
CRON='1'
printf 'CRON=%s\n' "$CRON" >>/app/.internal/cron.env

# Run cron indefinitely
crontab /app/crontab.cron
cron -L 15
printf 'started\n' >/app/.internal/status
tail -F /log/cron.log
