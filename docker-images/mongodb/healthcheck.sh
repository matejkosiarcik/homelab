#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
[0-9][0-9][0-9]) milliseconds_format="%3N" ;;
*) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

log() {
    # $1 - log level
    # $2+ - message

    log_level="${1}"
    shift
    log_timestamp="$(date "${datetime_format}")"
    printf '%s\n' "${*}" | while IFS= read -r log_message || [ -n "${log_message}" ]; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done | tee '/homelab/logs/healthcheck/healthcheck.log' >&2
}

# This condition ensures this script works with both versions of mongodb container images
# First is the official one with `mongosh` and second the unofficial/older one with plain `mongo`
mongo_shell=''
if command -v mongosh >'/dev/null'; then
    mongo_shell='mongosh'
elif command -v mongo >'/dev/null'; then
    mongo_shell='mongo'
else
    log ERROR 'No suitable mongo shell found'
    exit 1
fi

# printf "show databases\n" | "${mongo_shell}" "localhost:${PORT}/${MONGO_DBNAME}" --username "${MONGO_USER}" --password "${MONGO_PASSWORD}" --quiet || exit 1
"${mongo_shell}" <<EOF
use ${MONGO_AUTHSOURCE}
db.auth("${MONGO_INITDB_ROOT_USERNAME}", "${MONGO_INITDB_ROOT_PASSWORD}")
show databases
EOF
