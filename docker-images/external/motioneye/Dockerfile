# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM ghcr.io/motioneye-project/motioneye:edge
ENV HOMELAB_CONTAINER_NAME=motioneye \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:8765 || exit 1" ]
