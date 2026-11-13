# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_8: Must run as root initially, and the linuxserver.io image switches to nonroot after it starts

### Healthcheck ###

FROM golang:1.27.4-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### User setup ###

FROM gcr.io/distroless/static-debian13:latest@sha256:1a64f46364620465ef9e9a8f5413757dfdf22695e050bbfd7303eeaf17a59383 AS user_setup_base

FROM debian:13.7-slim AS user_setup
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_tvheadend_user_setup_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_tvheadend_user_setup_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh '/homelab/create-user.sh' && \
    grep -E '^homelab:' </etc/group | sed 's~^homelab~abc~' | sponge --append /etc/group && \
    grep -E '^homelab:' </etc/passwd | sed 's~^homelab~abc~' | sponge --append /etc/passwd && \
    grep -E '^homelab:' </etc/group | sed 's~^homelab~video123~' | sponge --append /etc/group && \
    grep -E '^homelab:' </etc/passwd | sed 's~^homelab~video123~' | sponge --append /etc/passwd && \
    usermod --append --groups root abc && \
    usermod --append --groups video123 abc && \
    pwconv && \
    passwd --lock homelab && \
    passwd --lock abc && \
    passwd --lock video123
# groupmod --gid 44 video123

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab

### Final ###

FROM linuxserver/tvheadend:latest@sha256:989fd717b2b143b8861ab60c31053c1d3542368532af1d429e996fa61e4fc04b AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
ARG GID=1000
ARG UID=1000
ENV HOMELAB_CONTAINER_NAME="tvheadend" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PGID="${GID}" \
    PUID="${UID}" \
    TZ="Europe/Bratislava"
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:9981" ]
