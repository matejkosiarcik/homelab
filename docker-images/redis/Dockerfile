# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.5-slim AS user-setup
USER root
WORKDIR /homelab
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab
ARG CONFIG_FILE=default
COPY ./docker-images/redis/${CONFIG_FILE}.conf /homelab/redis.conf
COPY ./docker-images/redis/entrypoint.sh /homelab/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

FROM redis:8.4.0
USER root
# RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=redis-final-aptcache \
#     --mount=type=cache,target=/var/lib/apt,sharing=locked,id=redis-final-aptlibcache \
#     apt-get update -qq && \
#     DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
#         openssl && \
#     rm -rf /var/lib/apt/lists/*
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
ENV HOMELAB_CONTAINER_NAME=redis \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "redis-cli --raw incr ping || exit 1" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
CMD []
