# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM debian:13.0-slim AS prefinal
WORKDIR /homelab
RUN mkdir -p ./certs ./logs
COPY ./custom/apache/www/ ./www/
COPY ./custom/apache/entrypoint.sh ./

FROM debian:13.0-slim
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends \
        apache2 curl inotify-tools && \
    rm -rf /var/lib/apt/lists/* && \
    a2enmod auth_basic env headers http2 macro proxy proxy_http proxy_http2 proxy_wstunnel rewrite ssl status && \
    a2dismod -f alias && \
    rm -rf /etc/apache2/sites-enabled/* /var/www/html/*
ARG UID
ARG GID
RUN groupadd -g $GID user && \
    useradd -m -u $UID -g $GID user
WORKDIR /homelab
# For debugging enable following modules: dump_io log_forensic
# NOTE: "alias" module is disabled because it causes 403/404 errors, see also: https://serverfault.com/questions/153177/apache2-and-icons-path-behaving-differently
COPY --chown=user:user ./custom/apache/apache.conf /etc/apache2/sites-enabled/apache.conf
COPY --from=prefinal --chown=user:user /homelab/ ./
ENV HOMELAB_CONTAINER_NAME=apache \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --insecure --fail https://localhost/.apache || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
