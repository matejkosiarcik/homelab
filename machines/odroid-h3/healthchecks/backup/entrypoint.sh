#!/bin/sh
set -euf

crontab /app/schedule.cron
crond -f -l 0 # -L /app/log/cron.log
