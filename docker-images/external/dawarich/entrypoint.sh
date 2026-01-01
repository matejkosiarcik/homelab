#!/bin/sh
set -euf

# Copy files to real "/var/app/db"
mkdir -p /var/app/db
cp -R /homelab/original/var/app/db/. /var/app/db

if [ "$MODE" = app ]; then
    bash ./docker/web-entrypoint.sh bin/dev server -p 3000 -b ::
elif [ "$MODE" = sidekiq ]; then
    bash ./docker/sidekiq-entrypoint.sh sidekiq
else
    printf 'Unknown mode %s\n' "$MODE" >&2
    exit 1
fi
