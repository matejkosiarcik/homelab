# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### App ###

FROM registry:3.1.2 AS docker_registry_app
USER root

### Dependencies ###

FROM golang:1.27.1-trixie AS envsubst_build
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_envsubst_build_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_envsubst_build_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/envsubst/go.mod /homelab/
ENV CGO_ENABLED="0"
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    envsubst_version="$(cat /homelab/go.mod | grep "github.com/a8m/envsubst" | cut -d ' ' -f 3)" && \
    go install -ldflags='-s -w -buildid=' -buildvcs=false "github.com/a8m/envsubst/cmd/envsubst@${envsubst_version}" && \
    strip --strip-all /go/bin/envsubst
COPY ./docker-images/.shared/build-utils/validate-executable.sh /homelab/
RUN sh validate-executable.sh /go/bin/envsubst

### Healthcheck ###

FROM golang:1.27.1-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Other ###

FROM busybox:1.38.0-uclibc AS busybox
USER root
COPY ./docker-images/.shared/build-utils/busybox-copy.sh /homelab/
RUN sh /homelab/busybox-copy.sh

### Users ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

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
COPY ./docker-images/docker-registry/config.yml ./docker-images/docker-registry/entrypoint.sh /homelab/
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/
COPY --from=envsubst_build /go/bin/envsubst /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=docker_registry_app /bin/registry /fsroot/bin/
COPY --from=busybox /fsroot/bin /fsroot/bin

### Final ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS final
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/bin/ /bin/
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME="docker-registry" \
    HOMELAB_CONTAINER_VARIANT="default" \
    OTEL_TRACES_EXPORTER="none" \
    PATH="/homelab/bin:${PATH}" \
    TZ="Europe/Bratislava"
# TODO: Eventually enable OpenTelemetry
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost" ]
USER homelab
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
