FROM ghcr.io/davideshay/groceries-client:1.1.9
ARG GID=1000
ARG UID=1000
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
    mkdir -p /home/homelab /homelab /homelab/nginx-html && \
    chown -R homelab:homelab /home/homelab /homelab && \
    find /usr/share/nginx/html -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/usr/share/nginx/html/$(basename "$1")" "/homelab/nginx-html/$(basename "$1")"' - {} \; && \
    find /usr/share/nginx/html -mindepth 1 -maxdepth 1 -exec rm -rf {} \;
COPY --chown=homelab:homelab ./external/groceries-frontend/entrypoint-extra.sh /homelab/
RUN head -n 1 /docker-entrypoint.sh >/homelab/entrypoint-shebang.sh && \
    tail -n +2 /docker-entrypoint.sh >/homelab/entrypoint-without-shebang.sh && \
    cat /homelab/entrypoint-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-without-shebang.sh >/docker-entrypoint.sh
COPY --chown=homelab:homelab ./external/groceries-frontend/nginx.conf /etc/nginx/conf.d/default.conf
ENV COUCHDB_USER=admin \
    DEFAULT_API_URL=https://placeholder.matejhome.com/api \
    HOMELAB_CONTAINER_NAME=groceries-frontend \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:8100 || exit 1" ]
USER homelab
