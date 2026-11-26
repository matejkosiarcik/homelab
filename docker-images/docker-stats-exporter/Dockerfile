# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

### App ###

FROM wywywywy/docker_stats_exporter:20220516@sha256:1e56d63987bbb10fc78ccca97a388e14696e305f52738a1f063e54f04cea779b AS docker_stats_exporter_app

### Healthcheck ###

FROM golang:1.27.4-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280 AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Users ###

FROM gcr.io/distroless/static-debian13:latest@sha256:4c2cd1dee442c9a99924a378c7c126fac8fef14771579ef567c3f2bdd7a5122a AS user_setup_base

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS user_setup
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

FROM gcr.io/distroless/nodejs26-debian13:latest@sha256:b462e87a3db156aea160dd8a5306b85d02c3061ca0e3194fe0af81282a830ab0 AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
WORKDIR /homelab/app
ENV DOCKER_HOST="tcp://docker-sockguard:2375" \
    DOCKERSTATS_HOSTIP="docker-sockguard" \
    DOCKERSTATS_HOSTPORT="2375" \
    DOCKERSTATS_INTERVAL="60" \
    HOMELAB_CONTAINER_NAME="docker-stats-exporter" \
    HOMELAB_CONTAINER_VARIANT="default" \
    NODE_OPTIONS="--dns-result-order=ipv4first" \
    PATH="/homelab/bin:${PATH}" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "healthcheck", "--endpoint", "{\"url\":\"http://localhost:9487\"}" ]
ENTRYPOINT [ "/nodejs/bin/node", "/homelab/app/docker_stats_exporter.js" ]
