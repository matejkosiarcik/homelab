#!/bin/sh
set -euf

mkdir -p /homelab/logs
touch /homelab/logs/generic-access.log /homelab/logs/generic-error.log /homelab/logs/http-access.log /homelab/logs/http-error.log /homelab/logs/https-access.log /homelab/logs/https-error.log
chown -R homelab:homelab /homelab/logs

# Set HOMELAB_ENV
if [ "${HOMELAB_ENV-x}" = 'x' ]; then
    printf 'HOMELAB_ENV unset\n' >&2
    exit 1
fi
export HOMELAB_ENV

# Set HOMELAB_APP_TYPE
if [ "${HOMELAB_APP_TYPE-x}" = 'x' ]; then
    printf 'HOMELAB_APP_TYPE unset\n' >&2
    exit 1
fi
export HOMELAB_APP_TYPE

# Set HOMELAB_APP_EXTERNAL_DOMAIN
if [ "${HOMELAB_APP_EXTERNAL_DOMAIN-x}" = 'x' ]; then
    printf 'HOMELAB_APP_EXTERNAL_DOMAIN unset\n' >&2
    exit 1
fi
export HOMELAB_APP_EXTERNAL_DOMAIN

# Set PROXY_HTTP_PORT
if [ "$HOMELAB_ENV" = 'prod' ]; then
    PROXY_HTTP_PORT='80'
elif [ "$HOMELAB_ENV" = 'dev' ]; then
    PROXY_HTTP_PORT='8080'
else
    printf 'Unknown HOMELAB_ENV: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_ENV-N/A}" "$HOMELAB_APP_TYPE"
    exit 1
fi
export PROXY_HTTP_PORT

# Set PROXY_HTTPS_PORT
if [ "$HOMELAB_ENV" = 'prod' ]; then
    PROXY_HTTPS_PORT='443'
elif [ "$HOMELAB_ENV" = 'dev' ]; then
    PROXY_HTTPS_PORT='8443'
else
    printf 'Unknown HOMELAB_ENV: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_ENV-N/A}" "$HOMELAB_APP_TYPE"
    exit 1
fi
export PROXY_HTTPS_PORT

# Set PROXY_FORCE_HTTPS
if [ "${HOMELAB_FORCE_PROTOCOL-}" = 'HTTP' ]; then
    PROXY_FORCE_HTTPS='false'
elif [ "$HOMELAB_APP_TYPE" = 'unificontroller' ] && [ "$HOMELAB_CONTAINER_VARIANT" = 'admin-raw' ]; then
    PROXY_FORCE_HTTPS='false' # TODO: Enable HTTPS redirection after Let's Encrypt certificates
else
    PROXY_FORCE_HTTPS='true'
fi
export PROXY_FORCE_HTTPS

# Set PROXY_REDIRECT_TO_HTTP_OR_HTTPS
if [ "${HOMELAB_FORCE_PROTOCOL-}" = 'HTTP' ]; then
    PROXY_REDIRECT_TO_HTTP_OR_HTTPS='HTTP'
elif [ "${HOMELAB_FORCE_PROTOCOL-}" = 'HTTPS' ] || [ "$PROXY_FORCE_HTTPS" = 'true' ]; then
    PROXY_REDIRECT_TO_HTTP_OR_HTTPS='HTTPS'
else
    PROXY_REDIRECT_TO_HTTP_OR_HTTPS=''
fi
export PROXY_REDIRECT_TO_HTTP_OR_HTTPS

PROXY_PROMETHEUS_EXPORTER_URL='http://apache-prometheus-exporter:9117'
export PROXY_PROMETHEUS_EXPORTER_URL

# Wait for certificates to exist before starting
timeout 90s sh <<EOF
if [ -e '/homelab/certs/fullchain.pem' ]; then
    return 0
fi
printf 'Waiting for certificate before starting\n' >&2
while [ ! -e '/homelab/certs/fullchain.pem' ]; do
    sleep 1
done
sleep 1
EOF

# Watch certificates in background
inotifywait --monitor --event modify --format '%w%f' --include 'fullchain\.pem' '/homelab/certs' | xargs -n1 sh -c 'sleep 1 && printf "Detected new certificates - Restarting apache\n" && apachectl -k restart' - &

# Graceful shutdown
trap 'apachectl -k stop; exit 0' TERM

# Start apache
printf 'Starting Apache\n' >&2
apachectl -D FOREGROUND &
apache_pid="$!"

# Wait for apache process to exit
wait "$apache_pid"
