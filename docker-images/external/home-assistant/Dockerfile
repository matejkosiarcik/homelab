# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM homeassistant/home-assistant:2024.11.1
# Also available on: ghcr.io/home-assistant/home-assistant:...
ENV HOMELAB_CONTAINER_NAME=home-assistant \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:8123 || exit 1" ]
