#!/bin/sh
set -euf

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

printf 'starting\n' >'/homelab/tmpfs/status.txt'

# Setup Environment variables
CRON='0'
export CRON

# Run script initially
if [ "${HOMELAB_CRON_SKIP_INITIAL-}" != '1' ]; then
    log INFO 'Running initial cron job'
    sh '/homelab/cron-wrapper.sh'
fi

# Run cron indefinitely
CRON=1
printf 'started\n' >'/homelab/tmpfs/status.txt'

# Determine cronfile
cronfile=''
if [ "${HOMELAB_CONTAINER_NAME}" = 'web-automation' ]; then
    cronfile="/homelab/crontab-${HOMELAB_APP_TYPE}-${HOMELAB_CONTAINER_VARIANT}.cron"
else
    cronfile='/homelab/crontab.cron'
fi

if [ ! -e "${cronfile}" ]; then
    log ERROR "Crontab file ${cronfile} not found"
    exit 1
fi

# Prepare Graceful shutdown
trap 'exit 0' TERM

# Start HTTP server
if [ -e '/homelab/server/dist/main.js' ]; then
    log INFO 'Starting on-demand cron server'
    node '/homelab/server/dist/main.js' &
    node_pid="$!"
fi

# Start cron
log INFO "Starting cron schedule from ${cronfile}"
supercronic "${cronfile}" &
supercronic_pid="$!"

# Wait for subprocesses
wait "${supercronic_pid}"
if [ "${node_pid-x}" != x ]; then
    wait "${node_pid}"
fi
