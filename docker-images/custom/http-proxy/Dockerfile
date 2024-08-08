FROM debian:12.6-slim AS prefinal
WORKDIR /app
COPY ./custom/http-proxy/www/ ./www/
COPY ./custom/http-proxy/entrypoint.sh ./

FROM debian:12.6-slim
WORKDIR /app
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends apache2 curl inotify-tools && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /certs /log /log/access /log/error /log/forensic && \
    a2enmod auth_basic env headers http2 log_forensic macro proxy proxy_http proxy_http2 proxy_wstunnel rewrite ssl status && \
    rm -rf /etc/apache2/sites-enabled/* /var/www/html/* && \
    groupadd --system homelab && \
    useradd --gid homelab --system homelab && \
    chown -R homelab:homelab /app /certs /log && \
    chmod a+w /etc/apache2/envvars && \
    cat /etc/apache2/envvars | sed 's~APACHE_RUN_USER=www-data~APACHE_RUN_USER=homelab~;s~APACHE_RUN_GROUP=www-data~APACHE_RUN_GROUP=homelab~' >>/app/envvars && \
    cat /app/envvars >/etc/apache2/envvars && \
    rm -f /app/envvars && \
    mkdir -p /var/run/apache2 /var/lock/apache2 /var/log/apache2 && \
    chown -R homelab:homelab /var/run/apache2 /var/lock/apache2 /var/log/apache2
COPY ./custom/http-proxy/apache.conf /etc/apache2/sites-enabled/apache.conf
COPY --from=prefinal --chown=homelab:homelab /app/ ./
EXPOSE 80
EXPOSE 443
ENV APACHE_HTTP_PORT_NUMBER=80 \
    APACHE_HTTPS_PORT_NUMBER=443 \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=20s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --insecure --fail https://localhost/.proxy || exit 1" ]
# TODO: Update to --interval=10s --start-period=15s
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
