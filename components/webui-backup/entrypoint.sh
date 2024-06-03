#!/bin/sh
set -euf

rm -rf /app/.internal
mkdir -p /app/.internal
printf 'starting\n' >/app/.internal/status

rm -f /log/cron.log
touch /log/cron.log
crontab /app/schedule.cron

# Run script on startup
{
    printf '## Container startup ##\n'
    sh /app/run.sh 2>&1
    printf '## Starting cron ##\n'
} >>/log/cron.log

crond -b -L /log/cron.log # Add `-l 0` when debugging (note: alpine)
printf 'started\n' >/app/.internal/status
tail -F /log/cron.log
