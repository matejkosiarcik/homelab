# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

# hadolint ignore=DL3007
FROM linuxserver/tvheadend:latest
RUN usermod -a -G root abc
ENV HOMELAB_CONTAINER_NAME=tvheadend \
    HOMELAB_CONTAINER_VARIANT=default \
    PUID=1000 \
    PGID=1000 \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:9981 || exit 1" ]
