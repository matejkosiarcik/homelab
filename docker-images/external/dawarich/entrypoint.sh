#!/bin/sh
set -euf

find '/var/app/db2' -mindepth 1 -maxdepth 1 -exec sh -c 'cp -r "/var/app/db2/$(basename "$1")" "/var/app/db/$(basename "$1")"' - {} \;

if [ "$MODE" = app ]; then
    bash ./docker/web-entrypoint.sh bin/rails server -p 3000 -b ::
elif [ "$MODE" = sidekiq ]; then
    bash ./docker/sidekiq-entrypoint.sh sidekiq
else
    printf 'Unknown mode %s\n' "$MODE" >&2
    exit 1
fi
