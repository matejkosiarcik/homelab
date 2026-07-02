# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### App ###

FROM registry:3.0.0 AS docker-registry-app
USER root

### Healthcheck ###

FROM golang:1.26.4-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/http-healthcheck/main.go ./.shared/healthchecks/http-healthcheck/go.mod ./.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=docker-registry-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=docker-registry-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Other ###

FROM busybox:1.35.0-uclibc AS busybox
USER root
COPY ./.shared/build-utils/busybox-copy.sh /homelab/
RUN sh /homelab/busybox-copy.sh

### Users ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.5-slim AS user-setup
USER root
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab
COPY ./docker-registry/config.yml ./docker-registry/entrypoint.sh /homelab/
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY --from=docker-registry-app /bin/registry /fsroot/bin/
COPY --from=busybox /fsroot/bin /fsroot/bin

### Final ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/bin/ /bin/
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME=docker-registry \
    HOMELAB_CONTAINER_VARIANT=default \
    OTEL_TRACES_EXPORTER=none \
    TZ=Europe/Bratislava
# TODO: Eventually enable OpenTelemetry
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost" ]
USER homelab
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
