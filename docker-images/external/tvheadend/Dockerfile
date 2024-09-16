# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

# hadolint ignore=DL3007
FROM linuxserver/tvheadend:latest
ENV HOMELAB_CONTAINER_NAME=tvheadend \
    HOMELAB_CONTAINER_VARIANT=default \
    PUID=1000 \
    PGID=1000 \
    TZ=Europe/Bratislava
