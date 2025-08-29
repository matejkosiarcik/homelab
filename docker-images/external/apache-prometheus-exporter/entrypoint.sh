#!/bin/sh
set -euf

prometheus-apache-exporter --insecure --scrape_uri="https://proxy-status:$PROXY_STATUS_PASSWORD@$APACHE_HOST/.apache/status?auto"
