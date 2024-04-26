#!/bin/sh
set -euf

crontab /app/schedule.cron

rm -f /log/cron.log
touch /log/cron.log
{
    printf '## Container startup ##\n'
    sh /app/run.sh 2>&1
    printf '## Starting cron ##\n'
} >>/log/cron.log
crond -b -L /log/cron.log # Add `-l 0` when debugging (note: alpine)
tail -F /log/cron.log
