#!/bin/sh
set -euf

# This script wraps the main.sh script we are executing with calls to healthchecks
# It calls healthchecks both before and after the main script is run, and reports it status and output to healthchecks

# Setup
tmpdir="$(mktemp -d)"
statusfile="$tmpdir/status.txt"
logfile="$tmpdir/output.log"
touch "$statusfile" "$logfile"
printf '0\n' >"$statusfile"

# Send start-signal to healthchecks
if [ -n "${HOMELAB_HEALTHCHECK_URL+x}" ]; then
    printf 'Send Healthchecks before job: '
    curl --location --request POST --retry 1 --max-time 10 --fail --silent --show-error "$HOMELAB_HEALTHCHECK_URL/start" || true
    printf '\n'
else
    printf 'HOMELAB_HEALTHCHECK_URL unset\n' >&2
    # TODO: Enable this after healthchecks are working
    # if [ "$HOMELAB_ENV" = 'prod' ]; then
    #     exit 1
    # fi
fi

if [ "$CRON" = '1' ]; then
    delay="$(bash -c 'echo $((1 + RANDOM % 60))')"
    printf 'Waiting %ss before starting cron job\n' "$delay"
    sleep "$delay"
fi

# Run actual job
(timeout 30m sh /homelab/main.sh 2>&1 || printf '%s\n' "$?" >"$statusfile") | tee "$logfile"

# Send end-signal to healthchecks
status="$(cat "$statusfile")"
if [ -n "${HOMELAB_HEALTHCHECK_URL+x}" ]; then
    printf 'Send Healthchecks after job: '
    curl --location --request POST --retry 1 --max-time 10 --fail --silent --show-error --data-binary "@$logfile" "$HOMELAB_HEALTHCHECK_URL/$status" || true
    printf '\n'
fi

# Cleanup
rm -rf "$tmpdir"

# Fail with error in case this is initial run
if [ "$CRON" = '0' ] && [ "$status" != '0' ]; then
    cat "$logfile" >&2
    exit "$status"
fi
