# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM louislam/uptime-kuma:1.23.13
ENV HOMELAB_CONTAINER_NAME=uptime-kuma \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=20s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:3001 || exit 1" ]
