# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM ghcr.io/kiwix/kiwix-serve:3.7.0
ENV HOMELAB_CONTAINER_NAME=kiwix \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
# HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:8096 || exit 1" ]
