# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM owntracks/recorder:1.0.1
ENV HOMELAB_CONTAINER_NAME=owntracks-backend \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --insecure --fail http://localhost:8083 || exit 1" ]
