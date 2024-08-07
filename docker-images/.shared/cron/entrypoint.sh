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

# Run script initially
sh /app/main.sh

# Run cron indefinitely
CRON=1
printf 'started\n' >/app/.internal/status
supercronic /app/crontab.cron
