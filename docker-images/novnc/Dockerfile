# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Healthcheck ###

FROM golang:1.27.1-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

FROM debian:13.7-slim AS user_setup
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

FROM debian:13.7-slim AS homelab_dir
WORKDIR /homelab
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/
COPY ./docker-images/novnc/entrypoint.sh /homelab/

FROM debian:13.7-slim AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab/

### Final ###

# hadolint ignore=DL3029
FROM debian:13.7-slim AS final
LABEL build.user=matejkosiarcik
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_supercronic_gitman_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_supercronic_gitman_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        novnc procps >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
# NOTE: Placeholders are replaced during runtime (in config or secrets)
ENV AUTOCONNECT="true" \
    HOMELAB_CONTAINER_NAME="novnc" \
    HOMELAB_CONTAINER_VARIANT="default" \
    TZ="Europe/Bratislava" \
    VNC_SERVER="PLACEHOLDER" \
    WEB_AUTH_USERNAME="matej" \
    WEB_AUTH_PASSWORD="PLACEHOLDER"
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:6080/vnc_lite.html", "--basic-auth-username-env", "WEB_AUTH_USERNAME", "--basic-auth-password-env", "WEB_AUTH_PASSWORD" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
