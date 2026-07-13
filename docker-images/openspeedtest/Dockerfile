# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest
# checkov:skip=CKV_DOCKER_8: Must run as root initially, and the image switches to nonroot after it starts

### Healthcheck ###

FROM golang:1.26.4-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=openspeedtest-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=openspeedtest-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Other ###

FROM openspeedtest/latest:v2.0.6 AS entrypoint
USER root
COPY ./docker-images/openspeedtest/entrypoint-extra.sh /homelab/
RUN head -n 1 /entrypoint.sh >/homelab/entrypoint-upstream-shebang.sh && \
    tail -n +2 /entrypoint.sh >/homelab/entrypoint-upstream-rest.sh && \
    cat /homelab/entrypoint-upstream-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-upstream-rest.sh >/homelab/entrypoint-final.sh && \
    chmod u=rx,go= /homelab/entrypoint-final.sh

FROM openspeedtest/latest:v2.0.6 AS runtime-dirs
USER root
RUN mkdir -p /homelab/original/etc/nginx/conf.d && \
    cp -R /etc/nginx/conf.d/. /homelab/original/etc/nginx/conf.d

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.5-slim AS user-setup
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=openspeedtest-user-setup-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=openspeedtest-user-setup-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh && \
    grep -E '^homelab:' </etc/group | sed 's~^homelab~nginx~' | sponge --append /etc/group && \
    grep -E '^homelab:' </etc/passwd | sed 's~^homelab~nginx~' | sponge --append /etc/passwd

### Prefinal ###

FROM scratch AS homelab-dir
USER root
WORKDIR /homelab
COPY --from=runtime-dirs /homelab/original /homelab/original
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY --from=entrypoint /homelab/entrypoint-final.sh /fsroot/entrypoint/entrypoint.sh

### Final ###

FROM openspeedtest/latest:v2.0.6
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
RUN chown -R homelab:homelab /etc/nginx && \
    chmod a+x "$(which crond)"
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/entrypoint/entrypoint.sh /
ARG GID=1000
ARG UID=1000
ENV ENABLE_LETSENCRYPT=False \
    HOMELAB_CONTAINER_NAME=openspeedtest \
    HOMELAB_CONTAINER_VARIANT=default \
    PGID=$GID \
    PUID=$UID \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:3000" ]
