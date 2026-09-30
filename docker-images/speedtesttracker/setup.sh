#!/bin/sh
set -euf

timeout 30s sh -c '
    until curl --silent --fail --insecure --max-time 2 "https://app:443/api/healthcheck" >/dev/null; do
        sleep 1
    done
'

if [ "${SPEEDTEST_RUN_TOKEN-}" = '' ]; then
    printf 'SPEEDTEST_RUN_TOKEN unset\n' >&2
    exit 1
fi

sleep 1

curl --fail --silent --show-error --insecure \
    --request POST 'https://app:443/api/v1/speedtests/run' \
    --header 'Accept: application/json' \
    --header "Authorization: Bearer ${SPEEDTEST_RUN_TOKEN}"
