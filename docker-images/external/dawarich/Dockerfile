# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM freikin/dawarich:0.30.8
ENV APPLICATION_PROTOCOL=http \
    BACKGROUND_PROCESSING_CONCURRENCY=10 \
    DATABASE_HOST=postgis \
    DATABASE_NAME=dawarich \
    DATABASE_USERNAME=postgres \
    HOMELAB_CONTAINER_NAME=dawarich \
    HOMELAB_CONTAINER_VARIANT=default \
    MIN_MINUTES_SPENT_IN_CITY=60 \
    RAILS_ENV=development \
    REDIS_URL=redis://redis:6379 \
    SELF_HOSTED=true \
    STORE_GEODATA=true \
    TIME_ZONE=Europe/Bratislava \
    TZ=Europe/Bratislava
RUN cp -R /var/app/db /var/app/db2 && \
    rm -rf /var/app/db
COPY ./external/dawarich/entrypoint.sh /homelab/
HEALTHCHECK --interval=10s --start-period=60s --timeout=5s --retries=1 CMD [ "sh", "-c", "wget -q -O - http://localhost:3000/api/v1/health | grep -q '\"status\"\\s*:\\s*\"ok\"' || exit 1" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
CMD []
