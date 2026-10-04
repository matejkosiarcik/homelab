# syntax=docker/dockerfile:1

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

FROM debian:13.7-slim AS user_setup
USER root
WORKDIR /homelab
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh '/homelab/create-user.sh' && \
    pwconv && \
    passwd --lock homelab

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab
COPY ./docker-images/wayvnc/config.txt ./docker-images/wayvnc/entrypoint.sh /homelab/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab

### Final ###

FROM debian:13.7-slim AS final
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_wayvnc_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_wayvnc_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        gettext-base wayvnc >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
ARG UID=1000
ENV HOMELAB_CONTAINER_NAME="wayvnc" \
    HOMELAB_CONTAINER_VARIANT="default" \
    TZ="Europe/Bratislava" \
    WAYVNC_PASSWORD="PLACEHOLDER" \
    WAYLAND_DISPLAY="wayland-0" \
    XDG_RUNTIME_DIR="/run/user/${UID}"
WORKDIR /homelab
USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "wayvncctl", "output-list" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
CMD []
