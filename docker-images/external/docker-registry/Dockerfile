# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM registry:3.0.0
COPY ./external/docker-registry/config.yml /etc/distribution/config.yml
ENV HOMELAB_CONTAINER_NAME=docker-registry \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "wget -O /dev/null http://localhost || exit 1" ]
