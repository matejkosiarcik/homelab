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

# Set PROXY_UPSTREAM_URL
if [ "$HOMELAB_APP_TYPE" = 'actualbudget' ]; then
    PROXY_UPSTREAM_URL="http://app:5006"
elif [ "$HOMELAB_APP_TYPE" = 'adventurelog' ]; then
    if [ "$HOMELAB_CONTAINER_VARIANT" = 'frontend' ]; then
        PROXY_UPSTREAM_URL="http://app-frontend:3000"
    elif [ "$HOMELAB_CONTAINER_VARIANT" = 'backend' ]; then
        PROXY_UPSTREAM_URL="http://app-backend:80"
    else
        printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}" "$HOMELAB_APP_TYPE"
        exit 1
    fi
elif [ "$HOMELAB_APP_TYPE" = 'certbot' ]; then
    PROXY_UPSTREAM_URL=''
elif [ "$HOMELAB_APP_TYPE" = 'changedetection' ]; then
    PROXY_UPSTREAM_URL="http://app:5000"
elif [ "$HOMELAB_APP_TYPE" = 'dawarich' ]; then
    PROXY_UPSTREAM_URL="http://app:3000"
elif [ "$HOMELAB_APP_TYPE" = 'docker-cache-proxy' ]; then
    PROXY_UPSTREAM_URL="http://app"
elif [ "$HOMELAB_APP_TYPE" = 'docker-stats' ]; then
    PROXY_UPSTREAM_URL="http://app:9487"
elif [ "$HOMELAB_APP_TYPE" = 'dozzle' ]; then
    PROXY_UPSTREAM_URL="http://app:8080"
elif [ "$HOMELAB_APP_TYPE" = 'gatus' ]; then
    PROXY_UPSTREAM_URL="http://app:8080"
# elif [ "$HOMELAB_APP_TYPE" = 'glances' ]; then
#     PROXY_UPSTREAM_URL="http://app:61208"
elif [ "$HOMELAB_APP_TYPE" = 'gotify' ]; then
    PROXY_UPSTREAM_URL="http://app:80"
elif [ "$HOMELAB_APP_TYPE" = 'grafana' ]; then
    PROXY_UPSTREAM_URL="http://app:3000"
elif [ "$HOMELAB_APP_TYPE" = 'groceries' ]; then
    PROXY_UPSTREAM_URL="http://app-frontend:8100"
elif [ "$HOMELAB_APP_TYPE" = 'healthchecks' ]; then
    PROXY_UPSTREAM_URL="http://app:8000"
elif [ "$HOMELAB_APP_TYPE" = 'homeassistant' ]; then
    PROXY_UPSTREAM_URL="http://app:8123"
elif [ "$HOMELAB_APP_TYPE" = 'homepage' ]; then
    PROXY_UPSTREAM_URL="http://app:3000"
elif [ "$HOMELAB_APP_TYPE" = 'jellyfin' ]; then
    PROXY_UPSTREAM_URL="http://app:8096"
elif [ "$HOMELAB_APP_TYPE" = 'kiwix' ]; then
    PROXY_UPSTREAM_URL="http://app:8080"
elif [ "$HOMELAB_APP_TYPE" = 'motioneye' ]; then
    PROXY_UPSTREAM_URL="http://app:8765"
elif [ "$HOMELAB_APP_TYPE" = 'minio' ]; then
    if [ "$HOMELAB_CONTAINER_VARIANT" = 'api' ]; then
        PROXY_UPSTREAM_URL="http://app:9000"
    elif [ "$HOMELAB_CONTAINER_VARIANT" = 'console' ]; then
        PROXY_UPSTREAM_URL="http://app:9001"
    else
        printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}" "$HOMELAB_APP_TYPE"
        exit 1
    fi
elif [ "$HOMELAB_APP_TYPE" = 'nodeexporter' ]; then
    PROXY_UPSTREAM_URL="http://app:9100"
elif [ "$HOMELAB_APP_TYPE" = 'ntfy' ]; then
    PROXY_UPSTREAM_URL="http://app"
elif [ "$HOMELAB_APP_TYPE" = 'ollama' ]; then
    PROXY_UPSTREAM_URL="http://app:11434"
elif [ "$HOMELAB_APP_TYPE" = 'omadacontroller' ]; then
    if [ "$HOMELAB_ENV" = 'dev' ]; then
        PROXY_UPSTREAM_URL="https://app:8443"
    elif [ "$HOMELAB_ENV" = 'prod' ]; then
        PROXY_UPSTREAM_URL="https://app"
    else
        printf 'Unknown HOMELAB_ENV: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_ENV-N/A}" "$HOMELAB_APP_TYPE"
        exit 1
    fi
elif [ "$HOMELAB_APP_TYPE" = 'openwebui' ]; then
    PROXY_UPSTREAM_URL="http://app:8080"
elif [ "$HOMELAB_APP_TYPE" = 'openspeedtest' ]; then
    PROXY_UPSTREAM_URL="http://app:3000" # HTTPS endpoint is also available, but plain HTTP results in better performance
elif [ "$HOMELAB_APP_TYPE" = 'pihole' ]; then
    PROXY_UPSTREAM_URL="http://app"
elif [ "$HOMELAB_APP_TYPE" = 'prometheus' ]; then
    PROXY_UPSTREAM_URL="http://app:9090"
elif [ "$HOMELAB_APP_TYPE" = 'renovatebot' ]; then
    PROXY_UPSTREAM_URL="http://app:8080"
elif [ "$HOMELAB_APP_TYPE" = 'samba' ]; then
    PROXY_UPSTREAM_URL="http://not-found"
elif [ "$HOMELAB_APP_TYPE" = 'smtp4dev' ]; then
    PROXY_UPSTREAM_URL="http://app:5000"
elif [ "$HOMELAB_APP_TYPE" = 'speedtesttracker' ]; then
    PROXY_UPSTREAM_URL="https://app"
elif [ "$HOMELAB_APP_TYPE" = 'tvheadend' ]; then
    PROXY_UPSTREAM_URL="http://app:9981"
elif [ "$HOMELAB_APP_TYPE" = 'unbound' ]; then
    PROXY_UPSTREAM_URL='http://not-found'
elif [ "$HOMELAB_APP_TYPE" = 'unificontroller' ]; then
    PROXY_UPSTREAM_URL="https://app:8443"
elif [ "$HOMELAB_APP_TYPE" = 'uptimekuma' ]; then
    PROXY_UPSTREAM_URL="http://app:3001"
elif [ "$HOMELAB_APP_TYPE" = 'vaultwarden' ]; then
    PROXY_UPSTREAM_URL="http://app"
elif [ "$HOMELAB_APP_TYPE" = 'vikunja' ]; then
    PROXY_UPSTREAM_URL="http://app:3456"
else
    printf 'Unknown HOMELAB_APP_TYPE: %s\n' "${HOMELAB_APP_TYPE-N/A}"
    exit 1
fi
export PROXY_UPSTREAM_URL

# Set PROXY_UPSTREAM_URL_STREAM
if [ "$HOMELAB_APP_TYPE" = 'motioneye' ]; then
    PROXY_UPSTREAM_URL_STREAM="http://app:9081"
else
    PROXY_UPSTREAM_URL_STREAM=''
fi
export PROXY_UPSTREAM_URL_STREAM

# Set PROXY_UPSTREAM_URL_WS
PROXY_UPSTREAM_URL_WS="$(printf '%s' "$PROXY_UPSTREAM_URL" | sed 's~https:~wss:~;s~http:~ws:~')"
export PROXY_UPSTREAM_URL_WS

# Set PROXY_HTTP_PORT
if [ "$HOMELAB_ENV" = 'prod' ]; then
    PROXY_HTTP_PORT='80'
elif [ "$HOMELAB_ENV" = 'dev' ]; then
    PROXY_HTTP_PORT='8080'
    if [ "$HOMELAB_APP_TYPE" = 'adventurelog' ] && [ "$HOMELAB_CONTAINER_VARIANT" = 'backend' ]; then
        PROXY_HTTP_PORT='8081'
    fi
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
    if [ "$HOMELAB_APP_TYPE" = 'adventurelog' ] && [ "$HOMELAB_CONTAINER_VARIANT" = 'backend' ]; then
        PROXY_HTTPS_PORT='8444'
    fi
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

# Set PROXY_UPSTREAM_URL_PROMETHEUS
if [ "$HOMELAB_APP_TYPE" = 'dawarich' ]; then
    PROXY_UPSTREAM_URL_PROMETHEUS='http://app:9394'
# elif [ "$HOMELAB_APP_TYPE" = 'glances' ]; then
#     PROXY_UPSTREAM_URL_PROMETHEUS='http://app-prometheus:61208'
elif [ "$HOMELAB_APP_TYPE" = 'pihole' ]; then
    PROXY_UPSTREAM_URL_PROMETHEUS='http://app-prometheus-exporter:9617'
elif [ "$HOMELAB_APP_TYPE" = 'samba' ]; then
    PROXY_UPSTREAM_URL_PROMETHEUS='http://app:9922'
elif [ "$HOMELAB_APP_TYPE" = 'unbound' ]; then
    PROXY_UPSTREAM_URL_PROMETHEUS='http://app-prometheus-exporter:9167'
else
    PROXY_UPSTREAM_URL_PROMETHEUS=''
fi
export PROXY_UPSTREAM_URL_PROMETHEUS

# Set PROXY_PROMETHEUS_EXPORTER_URL
if [ "$HOMELAB_APP_TYPE" = 'adventurelog' ]; then
    if [ "$HOMELAB_CONTAINER_VARIANT" = 'frontend' ]; then
        PROXY_PROMETHEUS_EXPORTER_URL='http://apache-prometheus-exporter-frontend:9117'
    elif [ "$HOMELAB_CONTAINER_VARIANT" = 'backend' ]; then
        PROXY_PROMETHEUS_EXPORTER_URL='http://apache-prometheus-exporter-backend:9117'
    else
        printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}" "$HOMELAB_APP_TYPE"
        exit 1
    fi
elif [ "$HOMELAB_APP_TYPE" = 'minio' ]; then
    if [ "$HOMELAB_CONTAINER_VARIANT" = 'api' ]; then
        PROXY_PROMETHEUS_EXPORTER_URL='http://apache-prometheus-exporter-api:9117'
    elif [ "$HOMELAB_CONTAINER_VARIANT" = 'console' ]; then
        PROXY_PROMETHEUS_EXPORTER_URL='http://apache-prometheus-exporter-console:9117'
    else
        printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}" "$HOMELAB_APP_TYPE"
        exit 1
    fi
else
    PROXY_PROMETHEUS_EXPORTER_URL='http://apache-prometheus-exporter:9117'
fi
export PROXY_PROMETHEUS_EXPORTER_URL

# Wait for certificates to exist before starting
timeout 60s sh <<EOF
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
