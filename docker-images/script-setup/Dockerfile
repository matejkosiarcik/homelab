# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Other ###

FROM debian:13.7-slim AS package_moreutils
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_script_setup_package_moreutils_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_script_setup_package_moreutils_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*

FROM debian:13.7-slim AS package_curl
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_script_setup_package_curl_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_script_setup_package_curl_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        curl >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /homelab/usr-lib && \
    find /usr/lib \( -name 'libbrotli*' -or -name 'libcom*' -or -name 'libcurl*' -or -name 'libffi*' -or -name 'libgmp*' -or -name 'libgnutls*' -or -name 'libgssapi*' -or -name 'libhogweed*' -or -name 'libidn*' -or -name 'libk*crypto*' -or -name 'libkeyutils*' -or -name 'libkrb*' -or -name 'liblber*' -or -name 'libldap*' -or -name 'libnettle*' -or -name 'libnghttp*' -or -name 'libp*kit*' -or -name 'libpsl*' -or -name 'librtmp*' -or -name 'libsasl*' -or -name 'libssh*' -or -name 'libtasn*' -or -name 'libunistring*' \) -exec sh -c 'mkdir -p "/homelab/usr-lib/$(dirname "${0}" | sed -E "s~^/usr/lib/~~")" && cp "${0}" "/homelab/usr-lib/$(dirname "${0}" | sed -E "s~^/usr/lib/~~")/$(basename "${0}")"' {} \;

FROM busybox:1.38.0-uclibc AS busybox
USER root
COPY ./docker-images/.shared/build-utils/busybox-copy.sh /homelab/
RUN sh /homelab/busybox-copy.sh

### Healthcheck ###

FROM golang:1.27.1-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/filecmp-healthcheck/main.go ./docker-images/.shared/healthchecks/filecmp-healthcheck/go.mod ./docker-images/.shared/healthchecks/filecmp-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

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
COPY ./docker-images/script-setup/entrypoint.sh /homelab/
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/
ARG SETUP_SCRIPT_DIR="script-setup"
COPY ./docker-images/${SETUP_SCRIPT_DIR}/setup.sh /homelab/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=busybox /fsroot/bin /fsroot/bin
COPY --from=package_moreutils /usr/bin/sponge /fsroot/usr-bin/
COPY --from=package_curl /usr/bin/curl /fsroot/usr-bin/
COPY --from=package_curl /homelab/usr-lib/ /fsroot/usr-lib/

### Final ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/base-debian13:latest AS final
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/bin/ /bin/
COPY --from=prefinal --chown=homelab:homelab /fsroot/usr-bin/ /usr/bin/
COPY --from=prefinal --chown=homelab:homelab /fsroot/usr-lib/ /usr/lib/
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME="script-setup" \
    HOMELAB_CONTAINER_VARIANT="default" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=90s --timeout=1s --retries=1 CMD [ "/homelab/bin/healthcheck", "--file", "/homelab/tmpfs/status.txt", "--content", "started" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
