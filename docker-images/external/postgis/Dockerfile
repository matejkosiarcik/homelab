# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM --platform=linux/amd64 postgis/postgis:17-3.5-alpine
ENV POSTGRES_DB=database \
    POSTGRES_USER=postgres \
    HOMELAB_CONTAINER_NAME=postgis \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB || exit 1" ]
