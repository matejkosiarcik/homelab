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
elif [ "$HOMELAB_APP_TYPE" = 'certificate-manager' ]; then
    PROXY_UPSTREAM_URL=''
elif [ "$HOMELAB_APP_TYPE" = 'changedetection' ]; then
    PROXY_UPSTREAM_URL="http://app:5000"
elif [ "$HOMELAB_APP_TYPE" = 'docker-cache-proxy' ]; then
    PROXY_UPSTREAM_URL="http://app"
elif [ "$HOMELAB_APP_TYPE" = 'dozzle-server' ]; then
    PROXY_UPSTREAM_URL="http://app:8080"
elif [ "$HOMELAB_APP_TYPE" = 'gatus' ]; then
    PROXY_UPSTREAM_URL="http://app:8080"
elif [ "$HOMELAB_APP_TYPE" = 'glances' ]; then
    PROXY_UPSTREAM_URL="http://app:61208"
elif [ "$HOMELAB_APP_TYPE" = 'healthchecks' ]; then
    PROXY_UPSTREAM_URL="http://app:8000"
elif [ "$HOMELAB_APP_TYPE" = 'homeassistant' ]; then
    PROXY_UPSTREAM_URL="http://app:8123"
elif [ "$HOMELAB_APP_TYPE" = 'homepage' ]; then
    PROXY_UPSTREAM_URL="http://app:3000"
elif [ "$HOMELAB_APP_TYPE" = 'jellyfin' ]; then
    PROXY_UPSTREAM_URL="http://app:8096"
elif [ "$HOMELAB_APP_TYPE" = 'motioneye' ]; then
    if [ "$HOMELAB_CONTAINER_VARIANT" = 'default' ]; then
        PROXY_UPSTREAM_URL="http://app:8765"
    elif [ "$HOMELAB_CONTAINER_VARIANT" = 'stream' ]; then
        PROXY_UPSTREAM_URL="http://app:9081"
    else
        printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}" "${HOMELAB_APP_TYPE}"
        exit 1
    fi
elif [ "$HOMELAB_APP_TYPE" = 'minio' ]; then
    if [ "$HOMELAB_CONTAINER_VARIANT" = 'api' ]; then
        PROXY_UPSTREAM_URL="http://app:9000"
    elif [ "$HOMELAB_CONTAINER_VARIANT" = 'console' ]; then
        PROXY_UPSTREAM_URL="http://app:9001"
    else
        printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}" "${HOMELAB_APP_TYPE}"
        exit 1
    fi
elif [ "$HOMELAB_APP_TYPE" = 'ntfy' ]; then
    PROXY_UPSTREAM_URL="http://app"
elif [ "$HOMELAB_APP_TYPE" = 'omada-controller' ]; then
    if [ "$HOMELAB_ENV" = 'dev' ]; then
        if [ "$HOMELAB_CONTAINER_VARIANT" = 'admin' ]; then
            PROXY_UPSTREAM_URL="https://app:8443"
        elif [ "$HOMELAB_CONTAINER_VARIANT" = 'portal' ]; then
            PROXY_UPSTREAM_URL="https://app:8444"
        else
            printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}" "${HOMELAB_APP_TYPE}"
            exit 1
        fi
    elif [ "$HOMELAB_ENV" = 'prod' ]; then
        if [ "$HOMELAB_CONTAINER_VARIANT" = 'admin' ]; then
            PROXY_UPSTREAM_URL="https://app"
        elif [ "$HOMELAB_CONTAINER_VARIANT" = 'portal' ]; then
            PROXY_UPSTREAM_URL="https://app:444"
        else
            printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}" "${HOMELAB_APP_TYPE}"
            exit 1
        fi
    else
        printf 'Unknown HOMELAB_ENV: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_ENV-N/A}" "${HOMELAB_APP_TYPE}"
        exit 1
    fi
elif [ "$HOMELAB_APP_TYPE" = 'openspeedtest' ]; then
    PROXY_UPSTREAM_URL="http://app:3000" # HTTPS endpoint is also available, but plain HTTP results in better performance
elif [ "$HOMELAB_APP_TYPE" = 'pihole' ]; then
    PROXY_UPSTREAM_URL="http://app"
elif [ "$HOMELAB_APP_TYPE" = 'prometheus' ]; then
    PROXY_UPSTREAM_URL="http://app:9090"
elif [ "$HOMELAB_APP_TYPE" = 'smtp4dev' ]; then
    PROXY_UPSTREAM_URL="http://app:5000"
elif [ "$HOMELAB_APP_TYPE" = 'speedtest-tracker' ]; then
    PROXY_UPSTREAM_URL="https://app"
elif [ "$HOMELAB_APP_TYPE" = 'tvheadend' ]; then
    PROXY_UPSTREAM_URL="http://app:9981"
elif [ "$HOMELAB_APP_TYPE" = 'unbound' ]; then
    PROXY_UPSTREAM_URL="http://not-found" # Just a placeholder
elif [ "$HOMELAB_APP_TYPE" = 'unifi-controller' ]; then
    if [ "$HOMELAB_CONTAINER_VARIANT" = 'admin' ] || [ "$HOMELAB_CONTAINER_VARIANT" = 'admin-raw' ]; then
        PROXY_UPSTREAM_URL="https://app:8443"
    elif [ "$HOMELAB_CONTAINER_VARIANT" = 'admin-raw-insecure' ]; then
        PROXY_UPSTREAM_URL="http://app:8080"
    elif [ "$HOMELAB_CONTAINER_VARIANT" = 'portal' ]; then
        PROXY_UPSTREAM_URL="https://app:8444"
    else
        printf 'Unknown HOMELAB_CONTAINER_VARIANT: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_CONTAINER_VARIANT-N/A}" "${HOMELAB_APP_TYPE}"
        exit 1
    fi
elif [ "$HOMELAB_APP_TYPE" = 'vaultwarden' ]; then
    PROXY_UPSTREAM_URL="http://app"
elif [ "$HOMELAB_APP_TYPE" = 'vikunja' ]; then
    PROXY_UPSTREAM_URL="http://app:3456"
else
    printf 'Unknown HOMELAB_APP_TYPE: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_APP_TYPE-N/A}" "${HOMELAB_APP_TYPE}"
    exit 1
fi
export PROXY_UPSTREAM_URL
printf "export PROXY_UPSTREAM_URL='%s'\n" "$PROXY_UPSTREAM_URL" >>/etc/apache2/envvars

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
    printf 'Unknown HOMELAB_ENV: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_ENV-N/A}" "${HOMELAB_APP_TYPE}"
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
    printf 'Unknown HOMELAB_ENV: %s for HOMELAB_APP_TYPE: %s\n' "${HOMELAB_ENV-N/A}" "${HOMELAB_APP_TYPE}"
    exit 1
fi
export PROXY_HTTPS_PORT
printf "export PROXY_HTTPS_PORT='%s'\n" "$PROXY_HTTPS_PORT" >>/etc/apache2/envvars

# Set PROXY_FORCE_HTTPS
if [ "${HOMELAB_FORCE_PROTOCOL-}" = 'HTTP' ]; then
    PROXY_FORCE_HTTPS='false'
elif [ "$HOMELAB_APP_TYPE" = 'ntfy' ]; then
    PROXY_FORCE_HTTPS='false' # TODO: Enable HTTPS redirection after Let's Encrypt certificates
elif [ "$HOMELAB_APP_TYPE" = 'unifi-controller' ] && [ "$HOMELAB_CONTAINER_VARIANT" = 'admin-raw' ]; then
    PROXY_FORCE_HTTPS='false' # TODO: Enable HTTPS redirection after Let's Encrypt certificates
elif [ "$HOMELAB_APP_TYPE" = 'tvheadend' ] && [ "$HOMELAB_CONTAINER_VARIANT" = 'direct' ]; then
    PROXY_FORCE_HTTPS='false' # TODO: Enable HTTPS redirection after Let's Encrypt certificates
elif [ "$HOMELAB_APP_TYPE" = 'jellyfin' ] && [ "$HOMELAB_CONTAINER_VARIANT" = 'direct' ]; then
    PROXY_FORCE_HTTPS='false' # TODO: Enable HTTPS redirection after Let's Encrypt certificates
elif [ "$HOMELAB_APP_TYPE" = 'openspeedtest' ]; then
    PROXY_FORCE_HTTPS='false'
elif [ "$HOMELAB_APP_TYPE" = 'vaultwarden' ]; then
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
    PROXY_UPSTREAM_URL_PROMETHEUS='http://prometheus-exporter'
elif [ "$HOMELAB_APP_TYPE" = 'unbound' ]; then
    PROXY_UPSTREAM_URL_PROMETHEUS='http://prometheus-exporter:9167'
else
    PROXY_UPSTREAM_URL_PROMETHEUS=''
fi
export PROXY_UPSTREAM_URL_PROMETHEUS
printf "export PROXY_UPSTREAM_URL_PROMETHEUS='%s'\n" "$PROXY_UPSTREAM_URL_PROMETHEUS" >>/etc/apache2/envvars

# Set PROXY_PROMETHEUS_EXPORTER_HOSTNAME
if [ "${PROXY_PROMETHEUS_EXPORTER_HOSTNAME-}" = '' ]; then
    PROXY_PROMETHEUS_EXPORTER_HOSTNAME='http-proxy-prometheus-exporter'
fi
export PROXY_PROMETHEUS_EXPORTER_HOSTNAME
printf "export PROXY_PROMETHEUS_EXPORTER_HOSTNAME='%s'\n" "$PROXY_PROMETHEUS_EXPORTER_HOSTNAME" >>/etc/apache2/envvars

# Wait for certificates to exist before starting
timeout 60s sh <<EOF
if [ -e '/homelab/certs/certificate.crt' ]; then
    return 0
fi
printf 'Waiting for certificate before starting\n' >&2
while [ ! -e '/homelab/certs/certificate.crt' ]; do
    sleep 1
done
sleep 1
EOF
# timeout 60s sh <<EOF
# if [ -e '/homelab/certs/fullchain.pem' ]; then
#     return 0
# fi
# printf 'Waiting for certificate before starting\n' >&2
# while [ ! -e '/homelab/certs/fullchain.pem' ]; do
#     sleep 1
# done
# sleep 1
# EOF

# Watch certificates in background
inotifywait --monitor --event modify --format '%w%f' --include 'certificate\.crt' '/homelab/certs' | xargs -n1 sh -c 'sleep 1 && printf "Detected new certificates - Restarting apache\n" && apachectl -k restart' - &
# inotifywait --monitor --event modify --format '%w%f' --include 'fullchain\.pem' '/homelab/certs' | xargs -n1 sh -c 'sleep 1 && printf "Detected new certificates - Restarting apache\n" && apachectl -k restart' - &

# Start apache
printf 'Starting Apache\n' >&2
apachectl -D FOREGROUND
