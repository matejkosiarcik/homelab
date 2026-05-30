# checkov:skip=CKV_DOCKER_8: Must run as root initially, the image switches to nonroot after it starts
# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in

### App ###

FROM mbentley/omada-controller:6.0 AS omadacontroller-app
USER root

### User setup ###

FROM gcr.io/distroless/static-debian13 AS user-setup-base

FROM debian:13.2-slim AS user-setup
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*
COPY --from=omadacontroller-app /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh && \
    cat /etc/group | grep -E '^homelab:' | sed 's~^homelab~omada~' | sponge --append /etc/group && \
    cat /etc/passwd | grep -E '^homelab:' | sed 's~^homelab~omada~' | sponge --append /etc/passwd && \
    cat /etc/group | grep -E '^homelab:' | sed 's~^homelab~mongodb~' | sponge --append /etc/group && \
    cat /etc/passwd | grep -E '^homelab:' | sed 's~^homelab~mongodb~' | sponge --append /etc/passwd

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

FROM mbentley/omada-controller:6.0
USER root
ARG GID=1000
ARG UID=1000
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
ENV HOMELAB_CONTAINER_NAME=omadacontroller \
    HOMELAB_CONTAINER_VARIANT=default \
    PGID=$GID \
    PUID=$UID \
    PORT_APP_DISCOVERY=27001 \
    PORT_ADOPT_V1=29812 \
    PORT_UPGRADE_V1=29813 \
    PORT_MANAGER_V1=29811 \
    PORT_MANAGER_V2=29814 \
    PORT_DISCOVERY=29810 \
    PORT_TRANSFER_V2=29815 \
    PORT_RTTY=29816 \
    PORT_DEVICE_MONITOR=29817 \
    SHOW_SERVER_LOGS=false \
    SHOW_MONGODB_LOGS=false \
    SSL_CERT_NAME=tls.crt \
    SSL_KEY_NAME=tls.key \
    TZ=Europe/Bratislava
