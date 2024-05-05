# hadolint ignore=DL3002
# checkov:skip=CKV_DOCKER_8: allow root user

FROM debian:12.5-slim
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends apache2 cron curl inotify-tools openssl && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /log /certs && \
    a2enmod auth_basic env headers http2 log_forensic macro proxy proxy_http proxy_http2 proxy_wstunnel rewrite ssl status && \
    rm -rf /etc/apache2/sites-enabled/* /var/www/html/*
COPY apache.conf /etc/apache2/sites-enabled/apache.conf
EXPOSE 80
EXPOSE 443
ENV APACHE_HTTP_PORT_NUMBER=80
ENV APACHE_HTTPS_PORT_NUMBER=443
# User necessary for binding to privileged ports
USER root
VOLUME [ "/app/www", "/app/misc" ]
HEALTHCHECK --interval=10s --retries=1 --start-period=15s --timeout=2s CMD curl --insecure --fail https://localhost/.proxy || exit 1
ENTRYPOINT [ "apachectl", "-D", "FOREGROUND" ]
