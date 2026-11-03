# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest
# checkov:skip=CKV_DOCKER_8: Must run as root initially, the image switches to nonroot after it starts

### Healthcheck ###

FROM golang:1.27.3-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

FROM debian:13.7-slim AS user_setup
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_omadacontroller_user_setup_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_omadacontroller_user_setup_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh '/homelab/create-user.sh' && \
    grep -E '^homelab:' </etc/group | sed 's~^homelab~omada~' | sponge --append /etc/group && \
    grep -E '^homelab:' </etc/passwd | sed 's~^homelab~omada~' | sponge --append /etc/passwd && \
    grep -E '^homelab:' </etc/group | sed 's~^homelab~mongodb~' | sponge --append /etc/group && \
    grep -E '^homelab:' </etc/passwd | sed 's~^homelab~mongodb~' | sponge --append /etc/passwd && \
    pwconv && \
    passwd --lock homelab && \
    passwd --lock omada && \
    passwd --lock mongodb

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab

### Final ###

FROM mbentley/omada-controller:6.3 AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
ARG GID=1000
ARG UID=1000
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
ENV HOMELAB_CONTAINER_NAME="omadacontroller" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PGID="${GID}" \
    PORT_ADOPT_V1="29812" \
    PORT_APP_DISCOVERY="27001" \
    PORT_DEVICE_MONITOR="29817" \
    PORT_DISCOVERY="29810" \
    PORT_MANAGER_V1="29811" \
    PORT_MANAGER_V2="29814" \
    PORT_RTTY="29816" \
    PORT_TRANSFER_V2="29815" \
    PORT_UPGRADE_V1="29813" \
    PUID="${UID}" \
    SHOW_MONGODB_LOGS="false" \
    SHOW_SERVER_LOGS="false" \
    SSL_CERT_NAME="" \
    SSL_KEY_NAME="" \
    TZ="Europe/Bratislava"
HEALTHCHECK --interval=10s --start-period=5m --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "exec /homelab/bin/healthcheck --url \"https://127.0.0.1:${MANAGE_HTTPS_PORT:-8043}/login\" --insecure --status '200'" ]
