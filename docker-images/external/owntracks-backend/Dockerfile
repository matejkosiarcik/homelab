# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM owntracks/recorder:1.0.0
# COPY ./external/owntracks-backend/entrypoint.sh /homelab/entrypoint.sh
ENV HOMELAB_CONTAINER_NAME=owntracks-backend \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --insecure --fail http://localhost:8083 || exit 1" ]
# ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
