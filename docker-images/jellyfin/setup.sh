#!/bin/sh
set -euf

config_file='/homelab/data/config/system.xml'

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N' 2>&1)"
case "${date_supports_milliseconds}" in
    [0-9][0-9][0-9])
        milliseconds_format="%3N"
        ;;
    *)
        milliseconds_format="000"
        ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

# Wait for config file to be created (mostly relevant for initial setup)
timeout 60s sh <<EOF
while [ ! -f "${config_file}" ]; do
    printf '%s [INFO]: Waiting for config file\n' "\$(date "${datetime_format}")" >&2
    sleep 1
done
while [ "$(wc -l <"${config_file}")" -eq 0 ]; do
    printf '%s [INFO]: Waiting for config file content\n' "\$(date "${datetime_format}")" >&2
    sleep 1
done
EOF
printf '%s [INFO]: Config file found\n' "$(date "${datetime_format}")" >&2

sleep "${HOMELAB_SETUP_DELAY-5}"

# Enable Prometheus metrics
sed 's~<EnableMetrics>false</EnableMetrics>~<EnableMetrics>true</EnableMetrics>~' <"${config_file}" | sponge "${config_file}"
if ! grep '<EnableMetrics>true</EnableMetrics>' <"${config_file}" >'/dev/null'; then
    printf '%s [ERROR]: Failed to enable prometheus metrics\n' "$(date "${datetime_format}")" >&2
    exit 1
else
    printf '%s [INFO]: Successfully enabled prometheus metrics\n' "$(date "${datetime_format}")" >&2
fi
