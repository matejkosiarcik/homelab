# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### App ###

FROM debian:13.6-slim AS apache_prometheus_exporter
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apache_prometheus_exporter_app_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apache_prometheus_exporter_app_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        prometheus-apache-exporter >/dev/null && \
    rm -rf /var/lib/apt/lists/*

### Healthcheck ###

FROM golang:1.27.1-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=healthcheck_build_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=healthcheck_build_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Other ###

FROM busybox:1.38.0-uclibc AS busybox
USER root
COPY ./docker-images/.shared/build-utils/busybox-copy.sh /homelab/
RUN sh /homelab/busybox-copy.sh

### Users ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

FROM debian:13.6-slim AS user_setup
USER root
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab_dir
USER root
WORKDIR /homelab
COPY ./docker-images/apache-prometheus-exporter/entrypoint.sh /homelab/
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/
COPY --from=apache_prometheus_exporter /usr/bin/prometheus-apache-exporter /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=busybox /fsroot/bin /fsroot/bin

### Final ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/base-debian13:latest
USER root
WORKDIR /homelab
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/bin/ /bin/
ENV HOMELAB_CONTAINER_NAME="apache-prometheus-exporter" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PATH="/homelab/bin:${PATH}" \
    TZ="Europe/Bratislava"
USER homelab
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:9117/metrics" ]
