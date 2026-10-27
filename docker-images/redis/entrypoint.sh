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

redis_config_input_file='/homelab/redis.conf'
redis_config_output_file='/homelab/tmpfs/redis.conf'

envsubst -no-digit -no-unset -no-empty -i "${redis_config_input_file}" -o "${redis_config_output_file}" || {
    log ERROR "$(printf 'An error happened during processing of %s to %s' "${redis_config_input_file}" "${redis_config_output_file}")"
    exit 1
}

# Start
exec redis-server '/homelab/tmpfs/redis.conf'
