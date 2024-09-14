# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM homeassistant/home-assistant:2024.9.1
# FROM ghcr.io/home-assistant/home-assistant:2024.9.1
ENV TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=30s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:8123 || exit 1" ]
