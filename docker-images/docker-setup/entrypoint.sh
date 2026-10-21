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

printf 'starting\n' >'/homelab/tmpfs/status.txt'

# Wait for target container to start
timeout 30s sh <<EOF
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

log INFO "Waiting for container ${HOMELAB_SETUP_TARGET_CONTAINER}"
while [ "\$(docker ps --quiet --filter "name=^${HOMELAB_SETUP_TARGET_CONTAINER}\\$" --filter 'status=running')" == '' ]; do
    sleep 1
done
log INFO 'Container found'
EOF

sleep "${HOMELAB_SETUP_DELAY-10}"

log INFO 'Starting setup'
if [ -n "${HOMELAB_SETUP_TARGET_USER-}" ]; then
    docker exec --user "${HOMELAB_SETUP_TARGET_USER}" "${HOMELAB_SETUP_TARGET_CONTAINER}" sh '/homelab/setup.sh'
else
    docker exec "${HOMELAB_SETUP_TARGET_CONTAINER}" sh '/homelab/setup.sh'
fi
log INFO 'Finished setup'

printf 'started\n' >'/homelab/tmpfs/status.txt'
exec sleep infinity
