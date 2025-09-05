# checkov:skip=CKV_DOCKER_3: USER can't be set directly, because of the way linuxserver.io image works, but it should be active anyway because we set PUID/PGID

FROM linuxserver/jellyfin:10.10.7
ARG UID=1000
ARG GID=1000
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" )
ENV HOMELAB_CONTAINER_NAME=jellyfin \
    HOMELAB_CONTAINER_VARIANT=default \
    JELLYFIN_CACHE_DIR=/cache \
    JELLYFIN_LOG_DIR=/logs \
    PGID=$GID \
    PUID=$UID \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:8096 || exit 1" ]
