#!/bin/sh
set -euf

apache_exporter --insecure --scrape_uri="https://proxy-status:$PROXY_STATUS_PASSWORD@$APACHE_HOST/.apache/status?auto"
