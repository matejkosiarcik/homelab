#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9])
        milliseconds_format="%3N"
        ;;
    *)
        milliseconds_format="000"
        ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

REDIS_URL="redis://:${REDIS_PASSWORD}@redis:6379"
export REDIS_URL

# Copy files to real "/var/app/db"
mkdir -p '/var/app/db'
cp -R '/homelab/original/var/app/db/.' '/var/app/db'

if [ "${MODE}" = app ]; then
    exec bash './docker/web-entrypoint.sh' './bin/dev' server -p 3000 -b ::
elif [ "${MODE}" = sidekiq ]; then
    exec bash './docker/sidekiq-entrypoint.sh' sidekiq
else
    printf '%s [ERROR]: Unknown mode %s\n' "$(date "${datetime_format}")" "${MODE}" >&2
    exit 1
fi
