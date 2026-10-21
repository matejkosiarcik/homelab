#!/bin/sh
set -euf

config_file='/homelab/data/config/system.xml'

# Wait for config file to be created (mostly relevant for initial setup)
timeout 60s sh <<EOF
while [ ! -e "${config_file}" ] || [ "$(wc -l <"${config_file}")" -eq 0 ]; do
    printf '%s [INFO]: Waiting for config file\n' "$(date +"%Y-%m-%dT%H-%M-%SZ")" >&2
    sleep 1
done
EOF
printf '%s [INFO]: Config file found\n' "$(date +"%Y-%m-%dT%H-%M-%SZ")" >&2

sleep "${HOMELAB_SETUP_DELAY-5}"

# Enable Prometheus metrics
sed 's~<EnableMetrics>false</EnableMetrics>~<EnableMetrics>true</EnableMetrics>~' <"${config_file}" | sponge "${config_file}"
if ! grep '<EnableMetrics>true</EnableMetrics>' <"${config_file}" >'/dev/null'; then
    printf '%s [ERROR]: Failed to enable prometheus metrics\n' "$(date +"%Y-%m-%dT%H-%M-%SZ")" >&2
    exit 1
else
    printf '%s [INFO]: Successfully enabled prometheus metrics\n' "$(date +"%Y-%m-%dT%H-%M-%SZ")" >&2
fi
