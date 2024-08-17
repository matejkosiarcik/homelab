# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM louislam/uptime-kuma:1.23.13
ENV HOMELAB_CONTAINER_TYPE=uptime-kuma \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=20s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:3001 || exit 1" ]
