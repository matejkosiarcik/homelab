# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Build config ###

FROM debian:13.7-slim AS gitconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_gitconfig_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_gitconfig_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    printf '' >/root/.gitconfig
# TODO: Re-enable cache below:
# COPY ./docker-images/.shared/anticache.txt /homelab/
# RUN printf '' >/root/.gitconfig && \
#     { curl --fail --silent 'https://git-cache-github.matejhome.com' || exit 0; } && \
#     git config --global 'url.https://git-cache-github.matejhome.com/.insteadOf' 'https://github.com/'

### Dependencies ###

FROM python:3.15.1-slim AS gitman
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/dependencies/gitman/requirements.txt /homelab/
ENV PIP_DISABLE_PIP_VERSION_CHECK="1" \
    PIP_ROOT_USER_ACTION="ignore" \
    PYTHONDONTWRITEBYTECODE="1"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --no-compile --requirement './requirements.txt' --target './python-vendor' --quiet

### Supercronic ###

FROM python:3.15.1-slim AS docker_proxy_filter_gitman
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_docker_proxy_filter_gitman_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_docker_proxy_filter_gitman_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git retry >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/python-vendor /homelab/python-vendor
ENV GITMAN_CACHE="/root/.gitcache" \
    PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"
COPY ./docker-images/docker-proxy-filter/repository/gitman.yml /homelab/
COPY --from=gitconfig /root/.gitconfig /root/.gitconfig
RUN --mount=type=cache,target=/root/.gitcache,sharing=locked,id=homelab_gitman_gitcache \
    retry --times=3 -- gitman install --quiet
COPY ./docker-images/docker-proxy-filter/repository/patches/proxy.rs.patch /homelab/
WORKDIR /homelab/gitman-repositories/docker-proxy-filter
RUN git apply /homelab/proxy.rs.patch && \
    find '.' -type d -name '.git' -prune -exec rm -rf {} \;

FROM rust:1.99.1-trixie AS docker_proxy_filter_build
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_docker_proxy_filter_build_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_docker_proxy_filter_build_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        binutils build-essential file jq >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/cargo-cross/Cargo.toml ./docker-images/.shared/dependencies/cargo-cross/Cargo.lock /homelab/cargo-cross-dependency/
COPY ./docker-images/.shared/dependencies/cargo-cross/src /homelab/cargo-cross-dependency/src
WORKDIR /homelab/cargo-cross-dependency
RUN version="$(cargo metadata --format-version 1 | jq -r '.packages[] | select(.name == "cargo-cross").version')" && \
    cargo install "cargo-cross@${version}" && \
    rustup target add "$(uname -m)-unknown-linux-musl"
COPY --from=docker_proxy_filter_gitman /homelab/gitman-repositories/docker-proxy-filter/ /homelab/docker-proxy-filter/
WORKDIR /homelab/docker-proxy-filter
ENV OPENSSL_STATIC=1 \
    PKG_CONFIG_ALLOW_CROSS=1 \
    RUSTFLAGS="-C target-feature=+crt-static"
RUN PKG_CONFIG_SYSROOT_DIR="/opt/openssl-$(uname -m)-musl" && \
    export PKG_CONFIG_SYSROOT_DIR && \
    PKG_CONFIG_PATH="${PKG_CONFIG_SYSROOT_DIR}/lib/pkgconfig:${PKG_CONFIG_SYSROOT_DIR}/usr/lib/pkgconfig:${PKG_CONFIG_SYSROOT_DIR}/usr/share/pkgconfig" && \
    export PKG_CONFIG_PATH && \
    cargo cross build --release --target "$(uname -m)-unknown-linux-musl" && \
    strip --strip-all "./target/$(uname -m)-unknown-linux-musl/release/docker-proxy-filter" && \
    cp "./target/$(uname -m)-unknown-linux-musl/release/docker-proxy-filter" '/homelab/docker-proxy-filter-bin'
WORKDIR /homelab
COPY ./docker-images/.shared/build-utils/validate-executable.sh /homelab/
RUN sh './validate-executable.sh' './docker-proxy-filter-bin'

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

### Healthcheck ###

FROM golang:1.27.3-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=docker_proxy_filter_build /homelab/docker-proxy-filter-bin /usr/local/bin/docker-proxy-filter

### Final ###

FROM foxxmd/docker-proxy-filter:0.1.2 AS final
LABEL build.user=matejkosiarcik
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /usr/local/bin/docker-proxy-filter /usr/local/bin/docker-proxy-filter
ENV CONTAINER_LABELS="placeholder_abcdefghijklmnopqrstuvwxyz" \
    CONTAINER_NAMES="placeholder_abcdefghijklmnopqrstuvwxyz" \
    DOCKER_HOST="tcp://docker-socket-proxy:2375" \
    HOMELAB_CONTAINER_NAME="docker-proxy-filter" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PROXY_URL="http://docker-socket-proxy:2375" \
    SCRUB_ENVS="true" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "tcp://localhost:2375" ]
