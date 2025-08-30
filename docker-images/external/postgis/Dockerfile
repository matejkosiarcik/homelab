# hadolint ignore=DL3029
FROM --platform=linux/amd64 postgis/postgis:17-3.5
ARG UID=999
ARG GID=999
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab && \
    chown -R user:user /homelab
ENV POSTGRES_DB=database \
    POSTGRES_USER=postgres \
    HOMELAB_CONTAINER_NAME=postgis \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB || exit 1" ]
USER user
