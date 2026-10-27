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

log INFO 'Validating Renovate config'
# LOG_LEVEL='debug'
RENOVATE_CONFIG_FILE='/usr/src/app/test-config.js' renovate --dry-run=full --print-config
log INFO 'Renovate config is valid'

runwisp_config_input_file='/homelab/runwisp.toml'
runwisp_config_output_file='/homelab/tmpfs/runwisp.toml'

envsubst -no-digit -no-unset -no-empty -i "${runwisp_config_input_file}" -o "${runwisp_config_output_file}" || {
    log ERROR "$(printf 'An error happened during processing of %s to %s' "${runwisp_config_input_file}" "${runwisp_config_output_file}")"
    exit 1
}

log INFO 'Validating RunWisp config'
runwisp validate
log INFO 'RunWisp config is valid'

log INFO 'Starting RunWisp daemon'
exec runwisp daemon
