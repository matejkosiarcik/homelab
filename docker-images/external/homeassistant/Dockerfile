# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM homeassistant/home-assistant:2025.5.3
ENV HOMELAB_CONTAINER_NAME=homeassistant \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:8123 || exit 1" ]
