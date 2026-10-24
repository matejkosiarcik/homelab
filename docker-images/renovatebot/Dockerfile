# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### RunWisp ###

FROM runwisp/runwisp:1.7.1-debian-docker AS runwisp

### Other ###

FROM debian:13.7-slim AS empty_dir
USER root
RUN mkdir /empty

FROM golang:1.27.2-trixie AS envsubst_build
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
USER root
WORKDIR /homelab
COPY --from=empty_dir /empty /homelab/logs
COPY ./docker-images/.shared/cron-utils/cron-wrapper.sh ./docker-images/renovatebot/entrypoint.sh ./docker-images/renovatebot/main.sh ./docker-images/renovatebot/runwisp.toml /homelab/
COPY --from=runwisp /usr/local/bin/runwisp /homelab/bin/runwisp
COPY --from=envsubst_build /go/bin/envsubst /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY ./docker-images/renovatebot/config.js /usr/src/app/config.js

### Final ###

FROM renovate/renovate:44.181.1-full AS final
LABEL build.user=matejkosiarcik
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
RUN chown -R homelab:homelab '/usr/src/app' '/home/ubuntu'
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /usr/src/app/config.js /usr/src/app/
ENV HOMELAB_CONTAINER_NAME="renovatebot" \
    HOMELAB_CONTAINER_VARIANT="default" \
    HOMELAB_CRON_TIMEOUT="30m" \
    PATH="/homelab/bin:${PATH}" \
    RENOVATE_BASE_DIR="/tmp/renovate" \
    RUNWISP_CONFIG="/homelab/tmpfs/runwisp.toml" \
    RUNWISP_DATA="/runwisp" \
    RUNWISP_HOST="0.0.0.0" \
    RUNWISP_LOG_FORMAT="text" \
    RUNWISP_PORT="8080" \
    RUNWISP_SOCKET="/homelab/tmpfs/runwisp.sock" \
    RUNWISP_TRUSTED_PROXIES="172.16.0.0/12" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=1s --retries=1 CMD [ "/homelab/bin/runwisp", "status" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
