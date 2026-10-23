#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N' 2>&1)"
case "${date_supports_milliseconds}" in
[0-9][0-9][0-9]) milliseconds_format="%3N" ;;
*) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

# This script wraps the main.sh script we are executing with calls to healthchecks
# It calls healthchecks both before and after the main script is run, and reports it status and output to healthchecks

# Setup
taskid="$(date "+%Y-%m-%d_%H-%M-%S.${milliseconds_format}")"
taskdir="/homelab/logs/cron/${taskid}"
mkdir -p "${taskdir}"
statusfile="${taskdir}/status.txt"
logfile="${taskdir}/output.txt"
touch "${statusfile}" "${logfile}"
printf '0\n' >"${statusfile}"

log() {
    # $1 - log level
    # $2+ - message

    log_level="${1}"
    shift
    log_timestamp="$(date "${datetime_format}")"
    printf '%s\n' "${*}" | while IFS= read -r log_message; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done | tee -a "${logfile}" >&2
}

log INFO "Running job with ID ${taskid}"

# Send start-signal to healthchecks
if [ "${HOMELAB_HEALTHCHECK_URL-}" != '' ]; then
    log INFO 'Sending Healthchecks start signal'
    if ! healthchecks_output="$(curl --location --request POST --retry 1 --max-time 10 --fail --silent --show-error "${HOMELAB_HEALTHCHECK_URL}/start" 2>&1)"; then
        log WARNING "Failed to send Healthchecks start signal: ${healthchecks_output}"
    fi
else
    if [ "${HOMELAB_ENV}" = 'prod' ]; then
        log ERROR 'HOMELAB_HEALTHCHECK_URL unset'
        exit 1
    fi
    log WARNING 'HOMELAB_HEALTHCHECK_URL unset'
fi

if [ "${CRON}" = '1' ]; then
    delay="$(bash -c 'echo $((1 + RANDOM % 60))')"
    log INFO "Waiting ${delay}s before starting cron job"
    sleep "${delay}"
fi

# Lock lockfile for to run exclusively
locked="$(
    set +e
    mkdir '/tmp/cron.lockdir'
    printf '%s' "$?"
    set -e
)"
if [ "${locked}" -ne 0 ]; then
    log ERROR 'Another instance of the script is already running. Exiting.'
    exit 1
fi
trap "rm -rf '/tmp/cron.lockdir'" EXIT

# Run actual job
cron_job_timeout="${HOMELAB_CRON_TIMEOUT-10m}"
(timeout "${cron_job_timeout}" sh '/homelab/main.sh' 2>&1 || printf '%s\n' "$?" >"${statusfile}") | tee -a "${logfile}" >&2

# Send end-signal to healthchecks
status="$(cat "${statusfile}")"
if [ "${status}" = '0' ]; then
    log INFO 'Job completed successfully'
else
    log ERROR "Job failed with status ${status}"
fi

if [ "${HOMELAB_HEALTHCHECK_URL-}" != '' ]; then
    log INFO "Sending Healthchecks completion signal with status ${status}"
    if ! healthchecks_output="$(curl --location --request POST --retry 1 --max-time 10 --fail --silent --show-error --data-binary "@${logfile}" "${HOMELAB_HEALTHCHECK_URL}/${status}" 2>&1)"; then
        log WARNING "Failed to send Healthchecks completion signal: ${healthchecks_output}"
    fi
fi

# Fail with error in case this is initial (or on-demand) run
if [ "${CRON}" = '0' ] && [ "${status}" != '0' ]; then
    exit "${status}"
fi
