#!/bin/sh
set -euf

printf '\n' >>/etc/apache2/envvars

# Set HOMELAB_ENV
if [ "${HOMELAB_ENV-x}" = 'x' ]; then
    printf 'HOMELAB_ENV unset\n' >&2
    exit 1
fi
export HOMELAB_ENV
printf "export HOMELAB_ENV='%s'\n" "$HOMELAB_ENV" >>/etc/apache2/envvars

# Set HOMELAB_APP_TYPE
if [ "${HOMELAB_APP_TYPE-x}" = 'x' ]; then
    printf 'HOMELAB_APP_TYPE unset\n' >&2
    exit 1
fi
export HOMELAB_APP_TYPE
printf "export HOMELAB_APP_TYPE='%s'\n" "$HOMELAB_APP_TYPE" >>/etc/apache2/envvars

# Set HOMELAB_APP_EXTERNAL_DOMAIN
if [ "${HOMELAB_APP_EXTERNAL_DOMAIN-x}" = 'x' ]; then
    printf 'HOMELAB_APP_EXTERNAL_DOMAIN unset\n' >&2
    exit 1
fi
export HOMELAB_APP_EXTERNAL_DOMAIN
printf "export HOMELAB_APP_EXTERNAL_DOMAIN='%s'\n" "$HOMELAB_APP_EXTERNAL_DOMAIN" >>/etc/apache2/envvars

# Set PROXY_UPSTREAM_URL
if [ "$HOMELAB_APP_TYPE" = 'actualbudget' ]; then
    PROXY_UPSTREAM_URL="http://app:5006"
elif [ "$HOMELAB_APP_TYPE" = 'certbot' ]; then
    PROXY_UPSTREAM_URL=''
elif [ "$HOMELAB_APP_TYPE" = 'changedetection' ]; then
    PROXY_UPSTREAM_URL="http://app:5000"
elif [ "$HOMELAB_APP_TYPE" = 'docker-cache-proxy' ]; then
    PROXY_UPSTREAM_URL="http://app"
elif [ "$HOMELAB_APP_TYPE" = 'docker-stats' ]; then
    PROXY_UPSTREAM_URL="http://app:9487"
elif [ "$HOMELAB_APP_TYPE" = 'dozzle' ]; then
    PROXY_UPSTREAM_URL="http://app:8080"
elif [ "$HOMELAB_APP_TYPE" = 'gatus' ]; then
    PROXY_UPSTREAM_URL="http://app:8080"
elif [ "$HOMELAB_APP_TYPE" = 'glances' ]; then
    PROXY_UPSTREAM_URL="http://app:61208"
elif [ "$HOMELAB_APP_TYPE" = 'gotify' ]; then
    PROXY_UPSTREAM_URL="http://app:80"
elif [ "$HOMELAB_APP_TYPE" = 'grafana' ]; then
    PROXY_UPSTREAM_URL="http://app:3000"
elif [ "$HOMELAB_APP_TYPE" = 'healthchecks' ]; then
    PROXY_UPSTREAM_URL="http://app:8000"
elif [ "$HOMELAB_APP_TYPE" = 'home-assistant' ]; then
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
elif [ "$HOMELAB_APP_TYPE" = 'node-exporter' ]; then
    PROXY_UPSTREAM_URL="http://app:9100"
elif [ "$HOMELAB_APP_TYPE" = 'ntfy' ]; then
    PROXY_UPSTREAM_URL="http://app"
elif [ "$HOMELAB_APP_TYPE" = 'ollama' ]; then
    PROXY_UPSTREAM_URL="http://app:11434"
elif [ "$HOMELAB_APP_TYPE" = 'omada-controller' ]; then
    if [ "$HOMELAB_ENV" = 'dev' ]; then
        PROXY_UPSTREAM_URL="https://app:8443"
    elif [ "$HOMELAB_ENV" = 'prod' ]; then
        PROXY_UPSTREAM_URL="https://app"
    else
        printf 'Unknown HOMELAB_ENV: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_ENV-N/A}" "$HOMELAB_APP_TYPE"
        exit 1
    fi
elif [ "$HOMELAB_APP_TYPE" = 'open-webui' ]; then
    PROXY_UPSTREAM_URL="http://app:8080"
elif [ "$HOMELAB_APP_TYPE" = 'openspeedtest' ]; then
    PROXY_UPSTREAM_URL="http://app:3000" # HTTPS endpoint is also available, but plain HTTP results in better performance
elif [ "$HOMELAB_APP_TYPE" = 'owntracks' ]; then
    PROXY_UPSTREAM_URL="http://app-frontend"
elif [ "$HOMELAB_APP_TYPE" = 'pihole' ]; then
    PROXY_UPSTREAM_URL="http://app"
elif [ "$HOMELAB_APP_TYPE" = 'prometheus' ]; then
    PROXY_UPSTREAM_URL="http://app:9090"
elif [ "$HOMELAB_APP_TYPE" = 'samba' ]; then
    PROXY_UPSTREAM_URL="http://not-found"
elif [ "$HOMELAB_APP_TYPE" = 'smtp4dev' ]; then
    PROXY_UPSTREAM_URL="http://app:5000"
elif [ "$HOMELAB_APP_TYPE" = 'speedtest-tracker' ]; then
    PROXY_UPSTREAM_URL="https://app"
elif [ "$HOMELAB_APP_TYPE" = 'tvheadend' ]; then
    PROXY_UPSTREAM_URL="http://app:9981"
elif [ "$HOMELAB_APP_TYPE" = 'unbound' ]; then
    PROXY_UPSTREAM_URL='http://not-found'
elif [ "$HOMELAB_APP_TYPE" = 'unifi-controller' ]; then
    PROXY_UPSTREAM_URL="https://app:8443"
elif [ "$HOMELAB_APP_TYPE" = 'uptime-kuma' ]; then
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
printf "export PROXY_UPSTREAM_URL='%s'\n" "$PROXY_UPSTREAM_URL" >>/etc/apache2/envvars

# Set PROXY_UPSTREAM_URL_STREAM
if [ "$HOMELAB_APP_TYPE" = 'motioneye' ]; then
    PROXY_UPSTREAM_URL_STREAM="http://app:9081"
else
    PROXY_UPSTREAM_URL_STREAM=''
fi
export PROXY_UPSTREAM_URL_STREAM
printf "export PROXY_UPSTREAM_URL_STREAM='%s'\n" "$PROXY_UPSTREAM_URL_STREAM" >>/etc/apache2/envvars

# Set PROXY_UPSTREAM_URL_WS
PROXY_UPSTREAM_URL_WS="$(printf '%s' "$PROXY_UPSTREAM_URL" | sed 's~https:~wss:~;s~http:~ws:~')"
export PROXY_UPSTREAM_URL_WS
printf "export PROXY_UPSTREAM_URL_WS='%s'\n" "$PROXY_UPSTREAM_URL_WS" >>/etc/apache2/envvars

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
printf "export PROXY_HTTP_PORT='%s'\n" "$PROXY_HTTP_PORT" >>/etc/apache2/envvars

# Set PROXY_HTTPS_PORT
if [ "$HOMELAB_ENV" = 'prod' ]; then
    PROXY_HTTPS_PORT='443'
    if [ "$HOMELAB_APP_TYPE" = 'omada-controller' ] || [ "$HOMELAB_APP_TYPE" = 'unifi-controller' ]; then
        if [ "$HOMELAB_CONTAINER_VARIANT" = 'portal' ]; then
            PROXY_HTTPS_PORT='444'
        fi
    fi
elif [ "$HOMELAB_ENV" = 'dev' ]; then
    PROXY_HTTPS_PORT='8443'
    if [ "$HOMELAB_APP_TYPE" = 'omada-controller' ] || [ "$HOMELAB_APP_TYPE" = 'unifi-controller' ]; then
        if [ "$HOMELAB_CONTAINER_VARIANT" = 'portal' ]; then
            PROXY_HTTPS_PORT='8444'
        fi
    fi
else
    printf 'Unknown HOMELAB_ENV: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_ENV-N/A}" "$HOMELAB_APP_TYPE"
    exit 1
fi
export PROXY_HTTPS_PORT
printf "export PROXY_HTTPS_PORT='%s'\n" "$PROXY_HTTPS_PORT" >>/etc/apache2/envvars

# Set PROXY_FORCE_HTTPS
if [ "${HOMELAB_FORCE_PROTOCOL-}" = 'HTTP' ]; then
    PROXY_FORCE_HTTPS='false'
elif [ "$HOMELAB_APP_TYPE" = 'openspeedtest' ]; then
    PROXY_FORCE_HTTPS='false'
elif [ "$HOMELAB_APP_TYPE" = 'unifi-controller' ] && [ "$HOMELAB_CONTAINER_VARIANT" = 'admin-raw' ]; then
    PROXY_FORCE_HTTPS='false' # TODO: Enable HTTPS redirection after Let's Encrypt certificates
else
    PROXY_FORCE_HTTPS='true'
fi
export PROXY_FORCE_HTTPS
printf "export PROXY_FORCE_HTTPS='%s'\n" "$PROXY_FORCE_HTTPS" >>/etc/apache2/envvars

# Set PROXY_REDIRECT_TO_HTTP_OR_HTTPS
if [ "${HOMELAB_FORCE_PROTOCOL-}" = 'HTTP' ]; then
    PROXY_REDIRECT_TO_HTTP_OR_HTTPS='HTTP'
elif [ "${HOMELAB_FORCE_PROTOCOL-}" = 'HTTPS' ] || [ "$PROXY_FORCE_HTTPS" = 'true' ]; then
    PROXY_REDIRECT_TO_HTTP_OR_HTTPS='HTTPS'
else
    PROXY_REDIRECT_TO_HTTP_OR_HTTPS=''
fi
export PROXY_REDIRECT_TO_HTTP_OR_HTTPS
printf "export PROXY_REDIRECT_TO_HTTP_OR_HTTPS='%s'\n" "$PROXY_REDIRECT_TO_HTTP_OR_HTTPS" >>/etc/apache2/envvars

# Set PROXY_UPSTREAM_URL_PROMETHEUS
if [ "$HOMELAB_APP_TYPE" = 'glances' ]; then
    PROXY_UPSTREAM_URL_PROMETHEUS='http://app-prometheus:61208'
elif [ "$HOMELAB_APP_TYPE" = 'pihole' ]; then
    PROXY_UPSTREAM_URL_PROMETHEUS='http://app-prometheus-exporter'
elif [ "$HOMELAB_APP_TYPE" = 'samba' ]; then
    PROXY_UPSTREAM_URL_PROMETHEUS='http://app:9922'
elif [ "$HOMELAB_APP_TYPE" = 'unbound' ]; then
    PROXY_UPSTREAM_URL_PROMETHEUS='http://app-prometheus-exporter:9167'
else
    PROXY_UPSTREAM_URL_PROMETHEUS=''
fi
export PROXY_UPSTREAM_URL_PROMETHEUS
printf "export PROXY_UPSTREAM_URL_PROMETHEUS='%s'\n" "$PROXY_UPSTREAM_URL_PROMETHEUS" >>/etc/apache2/envvars

# Set PROXY_PROMETHEUS_EXPORTER_URL
if [ "$HOMELAB_APP_TYPE" = 'minio' ]; then
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
printf "export PROXY_PROMETHEUS_EXPORTER_URL='%s'\n" "$PROXY_PROMETHEUS_EXPORTER_URL" >>/etc/apache2/envvars

# Create placeholder files for certbot
if [ "$HOMELAB_APP_TYPE" = 'certbot' ]; then
    cp /homelab/www/.proxy/index.html /homelab/www/index.html
fi

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

# Start apache
printf 'Starting Apache\n' >&2
apachectl -D FOREGROUND
