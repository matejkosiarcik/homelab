# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM linuxserver/jellyfin:10.10.6
ENV HOMELAB_CONTAINER_NAME=jellyfin \
    HOMELAB_CONTAINER_VARIANT=default \
    PUID=1000 \
    PGID=1000 \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:8096 || exit 1" ]
