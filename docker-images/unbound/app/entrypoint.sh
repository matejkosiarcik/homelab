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

ls -lah '/homelab/sock' >'/dev/null' # This command has to be here, it seem to help with issue `touch: cannot touch '<file>': Operation not supported`
if [ ! -e '/homelab/sock/unbound.sock' ]; then
    touch '/homelab/sock/unbound.sock'
fi

if [ ! -e '/homelab/logs/unbound.log' ]; then
    touch '/homelab/logs/unbound.log'
    chmod 0666 '/homelab/logs/unbound.log'
fi

log INFO 'Checking config'
unbound-checkconf '/homelab/unbound.conf'
log INFO 'Config OK'

log INFO 'Starting unbound'
exec unbound -v -d -c '/homelab/unbound.conf'
