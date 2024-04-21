#!/bin/sh
set -euf

crontab /app/schedule.cron

rm -f /log/cron.log
touch /log/cron.log
printf '-- Container startup --\n' >>/log/cron.log
sh /app/run.sh >>/log/cron.log 2>&1

printf '-- Starting cron --\n' >>/log/cron.log
crond -b -L /log/cron.log # Add `-l 0` when debugging (note: alpine)
tail -f /log/cron.log
