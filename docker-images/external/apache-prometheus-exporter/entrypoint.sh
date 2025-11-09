#!/bin/sh
set -euf

# Prepare graceful shutdown
trap 'exit 0' TERM

apache_host='apache'
if [ "${HOMELAB_CONTAINER_VARIANT-}" != '' ] && [ "$HOMELAB_CONTAINER_VARIANT" != default ]; then
    apache_host="$apache_host-$HOMELAB_CONTAINER_VARIANT"
fi

# Start
prometheus-apache-exporter --insecure --scrape_uri="https://proxy-status:$PROXY_STATUS_PASSWORD@$apache_host/.apache/status?auto" &
program_pid="$!"
wait "$program_pid"
