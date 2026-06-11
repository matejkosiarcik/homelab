# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest
# checkov:skip=CKV_DOCKER_8: Must run as root

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.5-slim AS user-setup
USER root
WORKDIR /homelab
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

FROM linuxserver/socket-proxy:3.2.10
USER root
RUN apk update --no-cache && \
    apk add --no-cache bash
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
ENV ALLOW_RESTARTS=0 \
    ALLOW_START=0 \
    ALLOW_STOP=0 \
    AUTH=0 \
    BUILD=0 \
    COMMIT=0 \
    CONFIGS=0 \
    CONTAINERS=0 \
    DISABLE_IPV6=0 \
    DISTRIBUTION=0 \
    EVENTS=0 \
    EXEC=0 \
    HOMELAB_CONTAINER_NAME=socket-proxy \
    HOMELAB_CONTAINER_VARIANT=default \
    IMAGES=0 \
    INFO=0 \
    LOG_LEVEL=info \
    NETWORKS=0 \
    NODES=0 \
    PING=0 \
    PLUGINS=0 \
    POST=0 \
    SECRETS=0 \
    SERVICES=0 \
    SESSION=0 \
    SWARM=0 \
    SYSTEM=0 \
    TASKS=0 \
    TZ=Europe/Bratislava \
    VERSION=0 \
    VOLUMES=0
VOLUME /var/run/docker.sock
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "bash -c ':> /dev/tcp/localhost/2375' || exit 1" ]
