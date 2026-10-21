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
    done >&2
}

if [ "${#}" -lt 1 ]; then
    log ERROR 'Not enough arguments.'
    exit 1
fi

command="${1}"
shift

find '.' -mindepth 1 -maxdepth 1 -type d -not -name '.*' | sort | while read -r server; do
    cd "${server}" >'/dev/null'
    # shellcheck disable=SC2068
    task "${command}" ${@}
    cd - >'/dev/null'
done
