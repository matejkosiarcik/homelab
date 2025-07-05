# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM minio/minio:RELEASE.2025-06-13T11-33-47Z-cpuv1
ENV HOMELAB_CONTAINER_NAME=minio-server \
    HOMELAB_CONTAINER_VARIANT=default \
    MINIO_ROOT_USER=admin \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:9000/minio/health/live || exit 1" ]
