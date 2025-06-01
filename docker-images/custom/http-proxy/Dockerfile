# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM debian:12.11-slim AS prefinal
WORKDIR /homelab
RUN mkdir -p ./certs ./logs
COPY ./custom/apache/www/ ./www/
COPY ./custom/apache/entrypoint.sh ./

FROM debian:12.11-slim
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends \
        apache2 curl inotify-tools && \
    rm -rf /var/lib/apt/lists/* && \
    a2enmod auth_basic env headers http2 macro proxy proxy_http proxy_http2 proxy_wstunnel rewrite ssl status && \
    a2dismod -f alias && \
    rm -rf /etc/apache2/sites-enabled/* /var/www/html/*
# NOTE: "alias" module is disabled because it causes 403/404 errors, see also: https://serverfault.com/questions/153177/apache2-and-icons-path-behaving-differently
COPY ./custom/apache/apache.conf /etc/apache2/sites-enabled/apache.conf
COPY --from=prefinal /homelab/ ./
ENV HOMELAB_CONTAINER_NAME=apache \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --insecure --fail https://localhost/.proxy || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
