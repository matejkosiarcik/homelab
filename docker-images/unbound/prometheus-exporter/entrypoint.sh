#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9]) milliseconds_format="%3N" ;;
    *) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

timeout 30s sh <<EOF
while [ ! -e '/homelab/sock/unbound.sock' ]; do
    sleep 1
done
EOF

if [ ! -e '/homelab/sock/unbound.sock' ]; then
    printf '%s [ERROR]: /homelab/sock/unbound.sock not found\n' "$(date "${datetime_format}")" >&2
    exit 1
fi

exec unbound_exporter -unbound.host unix:///homelab/sock/unbound.sock
