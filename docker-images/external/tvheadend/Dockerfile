# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

# hadolint ignore=DL3007
FROM linuxserver/tvheadend:latest
RUN apk update --no-cache && \
    apk add --no-cache shadow
ARG UID=1000
ARG GID=1000
RUN usermod -a -G root abc && \
    groupadd video123 && \
    groupmod -g 44 video123 && \
    usermod -a -G video123 abc
ENV HOMELAB_CONTAINER_NAME=tvheadend \
    HOMELAB_CONTAINER_VARIANT=default \
    PGID=$GID \
    PUID=$UID \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:9981 || exit 1" ]
