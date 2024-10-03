# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM debian:12.7-slim AS prefinal
WORKDIR /homelab
RUN mkdir -p ./logs
COPY ./custom/http-redirect/www/ ./www/
COPY ./custom/http-redirect/entrypoint.sh ./

FROM debian:12.7-slim
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends \
        apache2 curl inotify-tools && \
    rm -rf /var/lib/apt/lists/* && \
    a2enmod auth_basic env headers macro rewrite status && \
    rm -rf /etc/apache2/sites-enabled/* /var/www/html/*
COPY ./custom/http-redirect/apache.conf /etc/apache2/sites-enabled/apache.conf
COPY --from=prefinal /homelab/ ./
ENV APACHE_HTTP_PORT_NUMBER=80 \
    APACHE_HTTPS_PORT_NUMBER=443 \
    HOMELAB_CONTAINER_NAME=http-redirect \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --insecure --fail https://localhost/.apache || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
