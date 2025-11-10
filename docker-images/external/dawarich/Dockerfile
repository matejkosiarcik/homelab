FROM freikin/dawarich:0.35.1
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
    mkdir -p /home/homelab /homelab && \
    chown -R homelab:homelab /home/homelab /homelab && \
    gem install foreman && \
    cp -R /var/app/db /var/app/db2 && \
    rm -rf /var/app/db && \
    chown -R homelab:homelab /var/app
COPY --chown=homelab:homelab ./external/dawarich/entrypoint.sh /homelab/
ENV APPLICATION_PROTOCOL=http \
    BACKGROUND_PROCESSING_CONCURRENCY=10 \
    DATABASE_HOST=postgis \
    DATABASE_NAME=dawarich \
    DATABASE_USERNAME=postgres \
    DISABLE_TELEMETRY=true \
    HOMELAB_CONTAINER_NAME=dawarich \
    HOMELAB_CONTAINER_VARIANT=default \
    MIN_MINUTES_SPENT_IN_CITY=60 \
    PROMETHEUS_EXPORTER_ENABLED=true \
    PROMETHEUS_EXPORTER_HOST=0.0.0.0 \
    PROMETHEUS_EXPORTER_PORT=9394 \
    RAILS_ENV=development \
    REDIS_URL=redis://redis:6379 \
    SELF_HOSTED=true \
    STORE_GEODATA=true \
    TIME_ZONE=Europe/Bratislava \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=5s --retries=1 CMD [ "sh", "-c", "wget -q -O - http://localhost:3000/api/v1/health | grep -q '\"status\"\\s*:\\s*\"ok\"' || exit 1" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
CMD []
USER homelab
