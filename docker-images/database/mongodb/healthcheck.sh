#!/bin/sh
set -euf

# This condition ensures this script works with both versions of mongodb container images
# First is the official one with `mongosh` and second the unofficial/older one with plain `mongo`
mongo_shell=''
if command -v mongosh >/dev/null; then
    mongo_shell='mongosh'
elif command -v mongo >/dev/null; then
    mongo_shell='mongo'
else
    printf 'No suitable mongo shell found\n' | tee '/homelab/logs/healthcheck.log' >&2
    exit 1
fi

printf "show databases\n" | "$mongo_shell" "localhost:$PORT/$DBNAME" --username "$USER" --password "$PASSWORD" --quiet || exit 1
