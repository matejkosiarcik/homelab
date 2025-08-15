# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM redis:8.2.0
ENV HOMELAB_CONTAINER_NAME=redis \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "redis-cli --raw incr ping || exit 1" ]
CMD [ "redis-server" ]
