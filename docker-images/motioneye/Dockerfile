# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
# checkov:skip=CKV_DOCKER_8: Must run as root

### Healthcheck ###

FROM golang:1.27.4-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280 AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### User setup ###

FROM gcr.io/distroless/static-debian13:latest@sha256:4c2cd1dee442c9a99924a378c7c126fac8fef14771579ef567c3f2bdd7a5122a AS user_setup_base

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS user_setup
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_motioneye_user_setup_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_motioneye_user_setup_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh '/homelab/create-user.sh' && \
    grep -E '^homelab:' </etc/group | sed 's~^homelab~motion~' | sponge --append /etc/group && \
    grep -E '^homelab:' </etc/passwd | sed 's~^homelab~motion~' | sponge --append /etc/passwd && \
    pwconv && \
    passwd --lock homelab && \
    passwd --lock motion

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab

### Final ###

FROM ghcr.io/motioneye-project/motioneye:0.44.0@sha256:7da31d62e6c46ee8b61280f872801e429ec6f3db81bb23aca11c83863939cade AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
ENV HOMELAB_CONTAINER_NAME="motioneye" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PATH="/homelab/bin:${PATH}" \
    TZ="Europe/Bratislava"
HEALTHCHECK --interval=10s --start-period=30s --timeout=5s --retries=1 CMD [ "healthcheck", "--endpoint", "{\"url\":\"http://localhost:8765\"}" ]
