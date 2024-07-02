# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM debian:12.6-slim
WORKDIR /app
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends apache2 cron curl inotify-tools openssl && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /log /certs && \
    a2enmod auth_basic env headers http2 log_forensic macro proxy proxy_http proxy_http2 proxy_wstunnel rewrite ssl status && \
    rm -rf /etc/apache2/sites-enabled/* /var/www/html/*
COPY apache.conf /etc/apache2/sites-enabled/apache.conf
COPY www/ ./www/
EXPOSE 80
EXPOSE 443
ENV APACHE_HTTP_PORT_NUMBER=80 \
    APACHE_HTTPS_PORT_NUMBER=443 \
    TZ=Europe/Bratislava
VOLUME [ "/app/www", "/app/misc" ]
HEALTHCHECK --interval=20s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --insecure --fail https://localhost/.proxy || exit 1" ]
# TODO: Update to --interval=10s --start-period=15s
ENTRYPOINT [ "apachectl", "-D", "FOREGROUND" ]
