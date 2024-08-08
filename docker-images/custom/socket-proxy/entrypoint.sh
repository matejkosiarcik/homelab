#!/bin/sh
set -euf

mkdir -p /app/.internal
printf 'starting\n' >/app/.internal/status

sh /app/main.sh

printf 'started\n' >/app/.internal/status
sleep infinity
