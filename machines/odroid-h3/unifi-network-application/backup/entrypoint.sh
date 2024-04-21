#!/bin/sh
set -euf

crontab /app/schedule.cron
touch /log/cron.log
crond -b -L /log/cron.log # Add `-l 0` when debugging (note: alpine)
tail -f /log/cron.log
