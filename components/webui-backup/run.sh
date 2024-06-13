#!/bin/sh
set -euf

PATH="$PATH:/usr/local/bin"
cd /app
# shellcheck source=/dev/null
. /app/.internal/.env

# Setup
tmpdir="$(mktemp -d)"
statusfile="$tmpdir/status.txt"
logfile="$tmpdir/output.log"

# Send start-status to healthchecks
if [ -n "${HEALTHCHECK_URL+x}" ]; then
    printf 'Healthchecks HTTP before: '
    curl --insecure --location --request POST --retry 1 --max-time 10 --fail --silent --show-error "$HEALTHCHECK_URL/start" || true
    printf '\n'
else
    printf 'HEALTHCHECK_URL unset\n' >&2
fi

# Run actual job
printf '0\n' >"$statusfile"
node "/app/dist/$HOMELAB_SERVICE.js" 2>&1 | tee "$logfile"

# Send status to healthchecks
status="$(cat "$statusfile")"
if [ -n "${HEALTHCHECK_URL+x}" ]; then
    printf 'Healthchecks HTTP after: '
    curl --insecure --location --request POST --retry 1 --max-time 10 --fail --silent --show-error --data-binary "@$logfile" "$HEALTHCHECK_URL/$status" || true
    printf '\n'
fi

# Cleanup
rm -rf "$tmpdir"
