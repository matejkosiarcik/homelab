FROM couchdb:3.5.0
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
    mkdir -p /home/homelab /homelab /homelab/local.d && \
    chown -R homelab:homelab /home/homelab /homelab && \
    find /opt/couchdb/etc/local.d -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/opt/couchdb/etc/local.d/$(basename "$1")" "/homelab/local.d/$(basename "$1")"' - {} \; && \
    rm -rf /opt/couchdb/etc/local.d
COPY --chown=homelab:homelab ./external/couchdb/jwt.ini /homelab/local.d/
COPY --chown=homelab:homelab ./external/couchdb/entrypoint-extra.sh /homelab/
RUN head -n 1 /docker-entrypoint.sh >/homelab/entrypoint-shebang.sh && \
    tail -n +2 /docker-entrypoint.sh >/homelab/entrypoint-without-shebang.sh && \
    cat /homelab/entrypoint-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-without-shebang.sh >/docker-entrypoint.sh
ENV COUCHDB_USER=admin \
    HOMELAB_CONTAINER_NAME=couchdb \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:5984/_up || exit 1" ]
USER homelab
