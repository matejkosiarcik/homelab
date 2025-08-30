# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM freikin/dawarich:0.30.12
ARG UID=1999
ARG GID=1999
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab && \
    chown -R user:user /homelab && \
    gem install foreman && \
    cp -R /var/app/db /var/app/db2 && \
    rm -rf /var/app/db && \
    chown -R user:user /var/app
COPY --chown=user:user ./external/dawarich/entrypoint.sh /homelab/
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
USER user
