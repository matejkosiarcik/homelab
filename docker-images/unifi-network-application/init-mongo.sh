#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

# This condition ensures this script works with both versions of mongodb container images
# First is the official one with `mongosh` and second the unofficial/older one with plain `mongo`
mongo_shell=''
if command -v mongosh >'/dev/null'; then
    mongo_shell='mongosh'
elif command -v mongo >'/dev/null'; then
    mongo_shell='mongo'
else
    printf '%s [ERROR]: No suitable mongo shell found\n' "$(date "${datetime_format}")" | tee -a '/homelab/logs/default/init-mongodb.log' >&2
    exit 1
fi

"${mongo_shell}" <<EOF
use ${MONGO_AUTHSOURCE}
db.auth("${MONGO_INITDB_ROOT_USERNAME}", "${MONGO_INITDB_ROOT_PASSWORD}")
db.createUser({
    user: "${MONGO_USER}",
    pwd: "${MONGO_PASSWORD}",
    roles: [
        { db: "admin", role: "clusterMonitor" },
        { db: "${MONGO_DBNAME}", role: "dbOwner" },
        { db: "${MONGO_DBNAME}_stat", role: "dbOwner" },
        { db: "${MONGO_DBNAME}_audit", role: "dbOwner" },
        { db: "${MONGO_DBNAME}_restore", role: "dbOwner" }
    ]
})
EOF
