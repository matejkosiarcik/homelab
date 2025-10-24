# checkov:skip=CKV_DOCKER_3: Cannot run as non-root initially, but we switch to another user later

FROM debian:13.1-slim AS prefinal
WORKDIR /homelab
RUN mkdir -p ./certs ./logs
COPY ./custom/apache/www/ ./www/
COPY ./custom/apache/entrypoint.sh ./

FROM debian:13.1-slim
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends \
        apache2 curl inotify-tools && \
    rm -rf /var/lib/apt/lists/* && \
    a2enmod auth_basic env headers http2 macro proxy proxy_http proxy_http2 proxy_wstunnel rewrite ssl status && \
    a2dismod -f alias && \
    rm -rf /etc/apache2/sites-enabled/* /var/www/html/*
ARG UID=1000
ARG GID=1000
RUN if [ "$(getent group "$GID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
        groupadd --gid "$GID" homelab && \
    true; else \
        oldgroupname="$(getent group "$GID" | cut -d: -f1)" && \
        groupmod --new-name homelab "$oldgroupname" && \
    true; fi && \
    nologinshell='' && \
    if [ -e /sbin/nologin ]; then \
        nologinshell='/sbin/nologin' && \
    true; elif [ -e /usr/sbin/nologin ]; then \
        nologinshell='/usr/sbin/nologin' && \
    true; else \
        nologinshell='/bin/false' && \
    true; fi && \
    if [ "$(getent passwd "$UID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
        useradd --no-log-init --home /home/homelab --uid "$UID" --gid "$GID" --shell "$nologinshell" homelab && \
    true; else \
        oldusername="$(getent passwd "$UID" | cut -d: -f1)" && \
        usermod --move-home --home /home/homelab --uid "$UID" --gid "$GID" --shell "$nologinshell" --login homelab "$oldusername" && \
    true; fi && \
    mkdir -p /home/homelab /homelab /homelab/users && \
    chown -R homelab:homelab /home/homelab /homelab && \
    touch /homelab/users/no-users.htpasswd
WORKDIR /homelab
# For debugging enable following modules: dump_io log_forensic
# NOTE: "alias" module is disabled because it causes 403/404 errors, see also: https://serverfault.com/questions/153177/apache2-and-icons-path-behaving-differently
COPY --chown=homelab:homelab ./custom/apache/apache.conf /etc/apache2/sites-enabled/apache.conf
COPY --from=prefinal --chown=homelab:homelab /homelab/ ./
ENV HOMELAB_CONTAINER_NAME=apache \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --insecure --fail https://localhost/.apache || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
