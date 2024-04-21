#!/bin/sh
set -euf

# Setup
tmpdir="$(mktemp -d)"
timestamp="$(date +"%Y-%m-%d_%H-%M-%S")"
statusfile="$tmpdir/status.txt"
logfile="$tmpdir/output.log"

# Send start-status to healthchecks
if [ ! -z "${HEALTHCHECK_URL+x}" ]; then
    printf 'Curl Healthchecks before: '
    curl --insecure --location --request POST --retry 2 --max-time 10 --fail --silent --show-error "$HEALTHCHECK_URL/start" || true
    printf '\n'
else
    printf 'HEALTHCHECK_URL unset\n' >&2
fi

# Run actual job
printf '0\n' >"$statusfile"
( pg_dump healthchecks \
    --data-only \
    --insert \
    --exclude-table-data=public.logs_record \
    --file=/backup/dump.sql 2>&1 \
    || printf '%s\n' "$?" >"$statusfile" ) | tee "$logfile"

# Send status to healthchecks
status="$(cat "$statusfile")"
if [ ! -z "${HEALTHCHECK_URL+x}" ]; then
    printf 'Curl Healthchecks after: '
    curl --insecure --location --request POST --retry 2 --max-time 10 --fail --silent --show-error --data-binary "@$logfile" "$HEALTHCHECK_URL/$status" || true
    printf '\n'
fi

# Cleanup
rm -rf "$tmpdir"
