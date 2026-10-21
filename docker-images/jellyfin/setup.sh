#!/bin/sh
set -euf

config_file='/homelab/data/config/system.xml'

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N' 2>&1)"
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

# Wait for config file to be created (mostly relevant for initial setup)
timeout 60s sh <<EOF
log() {
    # \$1 - log level
    # \$2+ - message

    log_level="\${1}"
    shift
    log_timestamp="\$(date "${datetime_format}")"
    printf '%s\n' "\${*}" | while IFS= read -r log_message || [ -n "\${log_message}" ]; do
        printf '%s [%s]: %s\n' "\${log_timestamp}" "\${log_level}" "\${log_message}"
    done >&2
}

while [ ! -f "${config_file}" ]; do
    log INFO 'Waiting for config file'
    sleep 1
done
while [ "$(wc -l <"${config_file}")" -eq 0 ]; do
    log INFO 'Waiting for config file content'
    sleep 1
done
EOF
log INFO 'Config file found'

sleep "${HOMELAB_SETUP_DELAY-5}"

# Enable Prometheus metrics
sed 's~<EnableMetrics>false</EnableMetrics>~<EnableMetrics>true</EnableMetrics>~' <"${config_file}" | sponge "${config_file}"
if ! grep '<EnableMetrics>true</EnableMetrics>' <"${config_file}" >'/dev/null'; then
    log ERROR 'Failed to enable prometheus metrics'
    exit 1
else
    log INFO 'Successfully enabled prometheus metrics'
fi
