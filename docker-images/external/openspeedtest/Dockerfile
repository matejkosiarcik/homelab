# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM openspeedtest/latest:v2.0.6
ENV HOMELAB_CONTAINER_NAME=openspeedtest \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:3000 || exit 1" ]
