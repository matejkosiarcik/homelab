# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM owntracks/frontend:2.15.3
ENV HOMELAB_CONTAINER_NAME=owntracks-frontend \
    HOMELAB_CONTAINER_VARIANT=default \
    SERVER_HOST=app-backend \
    SERVER_PORT=8083 \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --insecure --fail http://localhost || exit 1" ]
