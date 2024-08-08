#!/bin/sh
set -euf

mkdir -p /app/.internal
printf 'starting\n' >/app/.internal/status

# Setup Environment variables
CRON='0'
export CRON

# Run script initially
sh /app/main.sh

# Run cron indefinitely
CRON=1
printf 'started\n' >/app/.internal/status
supercronic /app/crontab.cron
