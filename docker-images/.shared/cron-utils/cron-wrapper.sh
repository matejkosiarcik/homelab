#!/bin/sh
set -euf

# This script wraps the main.sh script we are executing with calls to healthchecks
# It calls healthchecks both before and after the main script is run, and reports it status and output to healthchecks

# Setup
logdir="/homelab/logs/$(date +'%Y-%m-%d_%H-%M-%S')"
mkdir -p "$logdir"
statusfile="$logdir/status.txt"
logfile="$logdir/output.log"
touch "$statusfile" "$logfile"
printf '0\n' >"$statusfile"
printf 'Running job with ID %s\n' "$(basename "$logdir")" | tee -a "$logfile" >&2

# Send start-signal to healthchecks
if [ "${HOMELAB_HEALTHCHECK_URL-}" != '' ]; then
    printf 'Send Healthchecks before job: ' | tee -a "$logfile" >&2
    curl --location --request POST --retry 1 --max-time 10 --fail --silent --show-error "$HOMELAB_HEALTHCHECK_URL/start" || true
    printf '\n' | tee -a "$logfile" >&2
else
    printf 'HOMELAB_HEALTHCHECK_URL unset\n' | tee -a "$logfile" >&2
    # TODO: Enable this after healthchecks are working
    # if [ "$HOMELAB_ENV" = 'prod' ]; then
    #     exit 1
    # fi
fi

if [ "$CRON" = '1' ]; then
    delay="$(bash -c 'echo $((1 + RANDOM % 60))')"
    printf 'Waiting %ss before starting cron job\n' "$delay" | tee -a "$logfile" >&2
    sleep "$delay"
fi

# Lock lockfile for to run exclusively
locked="$(
    set +e
    mkdir /tmp/homelab-cron.lockd
    printf '%s' "$?"
    set -e
)"
if [ "$locked" -ne 0 ]; then
    printf '%s Another instance of the script is already running. Exiting.\n' "$(date +'%Y-%m-%dT%H:%M:%S')" | tee -a "$logfile" >&2
    exit 1
fi
trap 'rm -rf /tmp/homelab-cron.lockd' EXIT

# Run actual job
cron_job_timeout="${CRON_TIMEOUT-10m}"
(timeout "$cron_job_timeout" sh /homelab/main.sh 2>&1 || printf '%s\n' "$?" >"$statusfile") | tee -a "$logfile" >&2

# Send end-signal to healthchecks
status="$(cat "$statusfile")"
if [ "${HOMELAB_HEALTHCHECK_URL-}" != '' ]; then
    printf 'Send Healthchecks after job: ' | tee -a "$logfile" >&2
    curl --location --request POST --retry 1 --max-time 10 --fail --silent --show-error --data-binary "@$logfile" "$HOMELAB_HEALTHCHECK_URL/$status" || true
    printf '\n' | tee -a "$logfile" >&2
fi

# Fail with error in case this is initial (or on-demand) run
if [ "$CRON" = '0' ] && [ "$status" != '0' ]; then
    exit "$status"
fi
