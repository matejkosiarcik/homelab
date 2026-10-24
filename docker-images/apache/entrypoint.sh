#!/bin/sh
set -euf

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N')"
case "${date_supports_milliseconds}" in
[0-9][0-9][0-9]) milliseconds_format="%3N" ;;
*) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

log() {
    # $1 - log level
    # $2+ - message

    log_level="${1}"
    shift
    log_timestamp="$(date "${datetime_format}")"
    printf '%s\n' "${*}" | while IFS= read -r log_message; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done >&2
}
export datetime_format

mkdir -p '/homelab/logs/apache'
touch '/homelab/logs/apache/generic-access.log' '/homelab/logs/apache/generic-error.log' '/homelab/logs/apache/http-access.log' '/homelab/logs/apache/http-error.log' '/homelab/logs/apache/https-access.log' '/homelab/logs/apache/https-error.log'

# Set HOMELAB_ENV
if [ "${HOMELAB_ENV-x}" = 'x' ]; then
    log ERROR 'HOMELAB_ENV unset'
    exit 1
fi
export HOMELAB_ENV

# Set HOMELAB_APP_TYPE
if [ "${HOMELAB_APP_TYPE-x}" = 'x' ]; then
    log ERROR 'HOMELAB_APP_TYPE unset'
    exit 1
fi
export HOMELAB_APP_TYPE

# Set HOMELAB_APP_EXTERNAL_DOMAIN
if [ "${HOMELAB_APP_EXTERNAL_DOMAIN-x}" = 'x' ]; then
    log ERROR 'HOMELAB_APP_EXTERNAL_DOMAIN unset'
    exit 1
fi
export HOMELAB_APP_EXTERNAL_DOMAIN

# Set PROXY_HTTP_PORT
if [ "${HOMELAB_ENV}" = 'prod' ]; then
    PROXY_HTTP_PORT='80'
elif [ "${HOMELAB_ENV}" = 'dev' ]; then
    PROXY_HTTP_PORT='8080'
else
    log ERROR "$(printf 'Unknown HOMELAB_ENV: %s for HOMELAB_APP_TYPE: %s' "${HOMELAB_ENV-N/A}" "${HOMELAB_APP_TYPE}")"
    exit 1
fi
export PROXY_HTTP_PORT

# Set PROXY_HTTPS_PORT
if [ "${HOMELAB_ENV}" = 'prod' ]; then
    PROXY_HTTPS_PORT='443'
elif [ "${HOMELAB_ENV}" = 'dev' ]; then
    PROXY_HTTPS_PORT='8443'
else
    log ERROR "$(printf 'Unknown HOMELAB_ENV: %s for HOMELAB_APP_TYPE: %s' "${HOMELAB_ENV-N/A}" "${HOMELAB_APP_TYPE}")"
    exit 1
fi
export PROXY_HTTPS_PORT

# Set PROXY_EXTERNAL_HOST
if [ "${PROXY_HTTPS_PORT}" = '443' ]; then
    PROXY_EXTERNAL_HOST="${HOMELAB_APP_EXTERNAL_DOMAIN}"
else
    PROXY_EXTERNAL_HOST="${HOMELAB_APP_EXTERNAL_DOMAIN}:${PROXY_HTTPS_PORT}"
fi
export PROXY_EXTERNAL_HOST

# Set PROXY_FORCE_HTTPS
if [ "${HOMELAB_FORCE_PROTOCOL-}" = 'HTTP' ]; then
    PROXY_FORCE_HTTPS='false'
elif [ "${HOMELAB_APP_TYPE}" = 'unificontroller' ] && [ "${HOMELAB_CONTAINER_VARIANT}" = 'admin-raw' ]; then
    PROXY_FORCE_HTTPS='false' # TODO: Enable HTTPS redirection after Let's Encrypt certificates
else
    PROXY_FORCE_HTTPS='true'
fi
export PROXY_FORCE_HTTPS

# Set PROXY_REDIRECT_TO_HTTP_OR_HTTPS
if [ "${HOMELAB_FORCE_PROTOCOL-}" = 'HTTP' ]; then
    PROXY_REDIRECT_TO_HTTP_OR_HTTPS='HTTP'
elif [ "${HOMELAB_FORCE_PROTOCOL-}" = 'HTTPS' ] || [ "${PROXY_FORCE_HTTPS}" = 'true' ]; then
    PROXY_REDIRECT_TO_HTTP_OR_HTTPS='HTTPS'
else
    PROXY_REDIRECT_TO_HTTP_OR_HTTPS=''
fi
export PROXY_REDIRECT_TO_HTTP_OR_HTTPS

PROXY_PROMETHEUS_EXPORTER_URL='http://apache-prometheus-exporter:9117'
export PROXY_PROMETHEUS_EXPORTER_URL

# Wait for certificates to exist before starting
timeout 90s sh <<EOF
log() {
    # \$1 - log level
    # \$2+ - message

    log_level="\${1}"
    shift
    log_timestamp="\$(date "${datetime_format}")"
    printf '%s\n' "\${*}" | while IFS= read -r log_message || [ -n "\${log_message}" ]; do
        printf '%s [%s]: %s\n' "\${log_timestamp}" "\${log_level}" "\${log_message}"
    done >&2
}

if [ -e '/homelab/certs/fullchain.pem' ]; then
    return 0
fi
log INFO 'Waiting for certificate before starting'
while [ ! -e '/homelab/certs/fullchain.pem' ]; do
    sleep 1
done
sleep 1
EOF

# Watch certificates in background
inotifywait --monitor --event modify --format '%w%f' --include 'fullchain\.pem' '/homelab/certs' | while IFS= read -r _; do
    sleep 1
    log INFO 'Detected new certificates - Restarting apache'
    apachectl -k restart
done &

# Graceful shutdown
trap 'apachectl -k stop; exit 0' TERM

# Start apache
log INFO 'Starting Apache'
apachectl -D FOREGROUND &
apache_pid="${!}"

# Wait for apache process to exit
wait "${apache_pid}"
