# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM debian:12.7-slim AS prefinal
WORKDIR /app
COPY ./custom/http-proxy/www/ ./www/
COPY ./custom/http-proxy/entrypoint.sh ./

FROM debian:12.7-slim
WORKDIR /app
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends apache2 curl inotify-tools && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /certs /log && \
    a2enmod auth_basic env headers http2 log_forensic macro proxy proxy_http proxy_http2 proxy_wstunnel rewrite ssl status && \
    rm -rf /etc/apache2/sites-enabled/* /var/www/html/*
COPY ./custom/http-proxy/apache.conf /etc/apache2/sites-enabled/apache.conf
COPY --from=prefinal /app/ ./
EXPOSE 80
EXPOSE 443
ENV APACHE_HTTP_PORT_NUMBER=80 \
    APACHE_HTTPS_PORT_NUMBER=443 \
    HOMELAB_CONTAINER_NAME=http-proxy \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=15s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --insecure --fail https://localhost/.proxy || exit 1" ]
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
