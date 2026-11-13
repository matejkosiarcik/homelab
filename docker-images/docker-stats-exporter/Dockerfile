# syntax=docker/dockerfile:1

### App ###

FROM wywywywy/docker_stats_exporter:20220516 AS docker_stats_exporter_app

### Healthcheck ###

FROM golang:1.27.4-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Users ###

FROM gcr.io/distroless/static-debian13:latest@sha256:448810357cc8e67b7208988abdba0f5ec3d3aebee0a5b13eb624979792cffc0f AS user_setup_base

FROM debian:13.7-slim AS user_setup
USER root
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
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/
COPY --from=docker_stats_exporter_app /usr/src/app /homelab/app/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab

### Final ###

FROM gcr.io/distroless/nodejs26-debian13:latest@sha256:80631bd2f0e7ef192138a7409013b47d92fd11b8ff3bb35f5c0a65be3ecaea4c AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
WORKDIR /homelab/app
ENV DOCKER_HOST="tcp://docker-proxy-filter:2375" \
    DOCKERSTATS_HOSTIP="docker-proxy-filter" \
    DOCKERSTATS_HOSTPORT="2375" \
    DOCKERSTATS_INTERVAL="60" \
    HOMELAB_CONTAINER_NAME="docker-stats-exporter" \
    HOMELAB_CONTAINER_VARIANT="default" \
    NODE_OPTIONS="--dns-result-order=ipv4first" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:9487" ]
ENTRYPOINT [ "/nodejs/bin/node", "/homelab/app/docker_stats_exporter.js" ]
