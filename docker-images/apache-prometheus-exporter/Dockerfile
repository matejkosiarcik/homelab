# syntax=docker/dockerfile:1

### App ###

FROM debian:13.7-slim AS apache_prometheus_exporter
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_apache_prometheus_exporter_app_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_apache_prometheus_exporter_app_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        prometheus-apache-exporter >/dev/null && \
    rm -rf /var/lib/apt/lists/*

### Healthcheck ###

FROM golang:1.27.3-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Other ###

FROM busybox:1.38.0-uclibc AS busybox
USER root
RUN mkdir -p '/fsroot/bin' && \
    cp '/bin/sh' '/fsroot/bin/'

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
USER root
WORKDIR /homelab
COPY ./docker-images/apache-prometheus-exporter/entrypoint.sh /homelab/
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/
COPY --from=apache_prometheus_exporter /usr/bin/prometheus-apache-exporter /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=busybox /fsroot/bin /fsroot/bin

### Final ###

FROM gcr.io/distroless/base-debian13:latest@sha256:ca90dc2333005edbc15bccbd7cd61c08ee0fd9dd1fa5ac68bc72778e6659ec5d AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
WORKDIR /homelab
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/bin/ /bin/
ENV HOMELAB_CONTAINER_NAME="apache-prometheus-exporter" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PATH="/homelab/bin:${PATH}" \
    PROXY_STATUS_PASSWORD="" \
    TZ="Europe/Bratislava"
USER homelab
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:9117/metrics" ]
