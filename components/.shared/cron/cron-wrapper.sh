#!/bin/sh
set -euf

PATH="$PATH:/usr/local/bin"
cd /app
# shellcheck source=/dev/null
. /app/.internal/cron.env

# Setup
tmpdir="$(mktemp -d)"
statusfile="$tmpdir/status.txt"
logfile="$tmpdir/output.log"
touch "$statusfile" "$logfile"
printf '0\n' >"$statusfile"

# Send start-signal to healthchecks
if [ -n "${HEALTHCHECK_URL+x}" ]; then
    printf 'Healthchecks HTTP before: '
    curl --insecure --location --request POST --retry 1 --max-time 10 --fail --silent --show-error "$HEALTHCHECK_URL/start" || true
    printf '\n'
else
    printf 'HEALTHCHECK_URL unset\n' >&2
fi

# Run actual job
(sh /app/main.sh 2>&1 || printf '%s\n' "$?" >"$statusfile") | tee "$logfile"

# Send end-signal to healthchecks
status="$(cat "$statusfile")"
if [ -n "${HEALTHCHECK_URL+x}" ]; then
    printf 'Healthchecks HTTP after: '
    curl --insecure --location --request POST --retry 1 --max-time 10 --fail --silent --show-error --data-binary "@$logfile" "$HEALTHCHECK_URL/$status" || true
    printf '\n'
fi

# Cleanup
rm -rf "$tmpdir"

# Fail with error in case this is initial run
if [ "$CRON" = '0' ] && [ "$status" != '0' ]; then
    cat "$logfile" >&2
    exit "$status"
fi
