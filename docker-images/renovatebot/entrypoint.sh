#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N' 2>&1)"
case "${date_supports_milliseconds}" in
[0-9][0-9][0-9]) milliseconds_format="%3N" ;;
*) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

# Logging function
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

printf 'starting\n' >'/homelab/tmpfs/status.txt'

log INFO 'Validating Renovate config'
RENOVATE_CONFIG_FILE='/usr/src/app/test-config.js' renovate --dry-run=full --print-config
log INFO 'Renovate config is valid'

# Setup Environment variables
CRON='0'
export CRON

# Sleep indefinitely
CRON=1
printf 'started\n' >'/homelab/tmpfs/status.txt'
log INFO 'Renovatebot is sleeping now'
exec sleep infinity
