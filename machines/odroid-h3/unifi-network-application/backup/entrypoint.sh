#!/bin/sh
set -euf

crontab /app/schedule.cron
crond -b -l 0 -L /log/cron.log
tail -f /log/cron.log
