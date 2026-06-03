# syntax=docker/dockerfile:1

### Healthcheck ###

FROM golang:1.25.5-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/http-healthcheck/main.go ./.shared/healthchecks/http-healthcheck/go.mod ./.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Other ###

FROM openspeedtest/latest:v2.0.6 AS entrypoint
USER root
COPY ./external/openspeedtest/entrypoint-extra.sh /homelab/
RUN head -n 1 /entrypoint.sh >/homelab/entrypoint-shebang.sh && \
    tail -n +2 /entrypoint.sh >/homelab/entrypoint-without-shebang.sh && \
    cat /homelab/entrypoint-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-without-shebang.sh >/entrypoint.sh

FROM openspeedtest/latest:v2.0.6 AS runtime-dirs
USER root
RUN mkdir -p /homelab/original/etc/nginx/conf.d && \
    cp -R /etc/nginx/conf.d/. /homelab/original/etc/nginx/conf.d

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
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh && \
    cat /etc/group | grep -E '^homelab:' | sed 's~^homelab~nginx~' | sponge --append /etc/group && \
    cat /etc/passwd | grep -E '^homelab:' | sed 's~^homelab~nginx~' | sponge --append /etc/passwd

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
COPY --from=entrypoint /entrypoint.sh /entrypoint.sh

### Final ###

FROM openspeedtest/latest:v2.0.6
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
RUN chown -R homelab:homelab /etc/nginx && \
    chmod a+x "$(which crond)"
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /entrypoint.sh /entrypoint.sh
ARG GID=1000
ARG UID=1000
ENV ENABLE_LETSENCRYPT=False \
    HOMELAB_CONTAINER_NAME=openspeedtest \
    HOMELAB_CONTAINER_VARIANT=default \
    PGID=$GID \
    PUID=$UID \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:3000" ]
