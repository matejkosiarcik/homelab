# syntax=docker/dockerfile:1

### Dependencies ###

FROM golang:1.27.4-trixie@sha256:430985542100b871e108ccc00e8dcc5eef08ca14ee5825e98ebf563d8ffec4ee AS envsubst_build
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
    envsubst_version="$(grep "github.com/a8m/envsubst" <'/homelab/go.mod' | cut -d ' ' -f 3)" && \
    go install -ldflags='-s -w -buildid=' -buildvcs=false "github.com/a8m/envsubst/cmd/envsubst@${envsubst_version}" && \
    strip --strip-all /go/bin/envsubst && \
    mkdir -p /homelab/bin && \
    mv /go/bin/envsubst /homelab/bin/
COPY ./docker-images/.shared/build-utils/validate-executable.sh /homelab/
RUN sh validate-executable.sh /homelab/bin/envsubst

### Healthcheck ###

FROM golang:1.27.4-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280 AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Config ###

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS config
USER root
WORKDIR /homelab
COPY --from=envsubst_build /homelab/bin/envsubst /homelab/bin/
ENV PATH="/homelab/bin:${PATH}"
ARG HOMELAB_APP_TYPE="placeholder" \
    HOMELAB_APP_SHORTNAME="placeholder"
COPY ./docker-images/docker-sockguard/config/${HOMELAB_APP_TYPE}.yaml /homelab/input/sockguard.yaml
RUN mkdir -p /homelab/config && \
    envsubst -no-digit -no-unset -no-empty -i '/homelab/input/sockguard.yaml' -o '/homelab/config/sockguard.yaml'

### App ###

FROM codeswhat/sockguard:2.4.9@sha256:2fa18c54c22c65947727d9ae1a3e6d7c4804afa0a0cef59c28a54032aab2d3f5 AS sockguard_app

### Other ###

FROM busybox:1.38.0-uclibc@sha256:b2e35951f72501f6a99f1bf45bcfe6d4795be08c518c2f97d0ed2fe776958a3b AS busybox
USER root
RUN mkdir -p '/fsroot/bin' && \
    cp -a '/bin/date' '/bin/sh' '/fsroot/bin/'

### User setup ###

FROM gcr.io/distroless/static-debian13:latest@sha256:4c2cd1dee442c9a99924a378c7c126fac8fef14771579ef567c3f2bdd7a5122a AS user_setup_base

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS user_setup
USER root
WORKDIR /homelab
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
COPY --from=config /homelab/config/sockguard.yaml /homelab/sockguard.yaml
COPY --from=sockguard_app /sockguard /homelab/bin/sockguard
COPY ./docker-images/docker-sockguard/entrypoint.sh /homelab/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=busybox /fsroot/bin/ /fsroot/bin/

### Final ###

FROM scratch AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/bin/ /bin/
ENV AUTH="0" \
    BUILD="0" \
    COMMIT="0" \
    CONFIGS="0" \
    CONTAINERS="0" \
    DISTRIBUTION="0" \
    EVENTS="0" \
    EXEC="0" \
    GRPC="0" \
    IMAGES="0" \
    INFO="0" \
    NETWORKS="0" \
    NODES="0" \
    PING="0" \
    PLUGINS="0" \
    POST="0" \
    SECRETS="0" \
    SERVICES="0" \
    SESSION="0" \
    SWARM="0" \
    SYSTEM="0" \
    TASKS="0" \
    VERSION="0" \
    VOLUMES="0" \
    ALLOW_START="0" \
    ALLOW_STOP="0" \
    ALLOW_RESTART="0" \
    ALLOW_RESTARTS="0" \
    ALLOW_PAUSE="0" \
    ALLOW_UNPAUSE="0" \
    ALLOW_CREATE="0" \
    ALLOW_EXEC="0" \
    ALLOW_KILL="0" \
    ALLOW_DELETE="0" \
    ALLOW_PRUNE="0" \
    SOCKGUARD_ADMIN_ENABLED="false" \
    SOCKGUARD_ADMIN_LISTEN_INSECURE_ALLOW_PLAIN_TCP="false" \
    SOCKGUARD_ADMIN_LISTEN_INSECURE_ALLOW_UNAUTHENTICATED_CLIENTS="false" \
    SOCKGUARD_ADMIN_LISTEN_INSECURE_ALLOW_WIDE_OPEN="false" \
    DOCKER_HOST="tcp://docker-socket-proxy:2375" \
    SOCKGUARD_LISTEN_ADDRESS="0.0.0.0:2375" \
    SOCKGUARD_LISTEN_INSECURE_ALLOW_PLAIN_TCP="true" \
    SOCKGUARD_LISTEN_INSECURE_ALLOW_UNAUTHENTICATED_CLIENTS="true" \
    SOCKGUARD_HEALTH_ENABLED="true" \
    SOCKGUARD_HEALTH_PATH="/health" \
    SOCKGUARD_METRICS_ENABLED="true" \
    SOCKGUARD_INSECURE_ALLOW_READ_EXFILTRATION="false" \
    SOCKGUARD_UPSTREAM_FLAVOR="docker" \
    HOMELAB_CONTAINER_NAME="docker-sockguard" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PATH="/homelab/bin:${PATH}" \
    SOCKET_PATH="" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "healthcheck", "--endpoint", "{\"url\":\"http://localhost:2375/health\"}" ]
ENTRYPOINT ["sh", "/homelab/entrypoint.sh"]
