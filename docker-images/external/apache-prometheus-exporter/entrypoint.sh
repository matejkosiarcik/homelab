#!/bin/sh
set -euf

# TODO: Research if "--insecure" is still necessary after real Let's encrypt certificates
apache_exporter --insecure --scrape_uri="https://proxy-status:$PROXY_STATUS_PASSWORD@$APACHE_HOST/.proxy/status?auto"
