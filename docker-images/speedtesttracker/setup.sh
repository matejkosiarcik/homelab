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
    printf '%s\n' "${*}" | while IFS= read -r log_message; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done >&2
}

timeout 30s sh -c '
    until curl --silent --fail --insecure --max-time 2 "https://app:443/api/healthcheck" >/dev/null; do
        sleep 1
    done
'

if [ "${SPEEDTEST_RUN_TOKEN-}" = '' ]; then
    log ERROR 'SPEEDTEST_RUN_TOKEN unset'
    exit 1
fi

sleep 1

curl --fail --silent --show-error --insecure \
    --request POST 'https://app:443/api/v1/speedtests/run' \
    --header 'Accept: application/json' \
    --header "Authorization: Bearer ${SPEEDTEST_RUN_TOKEN}"
