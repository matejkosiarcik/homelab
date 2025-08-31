#!/bin/sh
set -euf

# Prepare graceful shutdown
trap 'exit 0' TERM

# Start
prometheus-apache-exporter --insecure --scrape_uri="https://proxy-status:$PROXY_STATUS_PASSWORD@$APACHE_HOST/.apache/status?auto" &
program_pid="$!"
wait "$program_pid"
