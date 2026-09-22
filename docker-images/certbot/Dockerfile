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
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/anticache.txt /homelab/
RUN printf '' >/root/.gitconfig && \
    { curl --fail --silent 'https://git-cache-github.matejhome.com' || exit 0; } && \
    git config --global 'url.https://git-cache-github.matejhome.com/.insteadOf' 'https://github.com/'

### Dependencies ###

FROM python:3.14.7-slim AS gitman
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/dependencies/gitman/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION="ignore"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --requirement './requirements.txt' --target './python-vendor' --quiet

### Supercronic ###

FROM python:3.14.7-slim AS supercronic_gitman
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_supercronic_gitman_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_supercronic_gitman_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git retry >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/python-vendor /homelab/python-vendor
ENV GITMAN_CACHE="/root/.gitcache" \
    PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"
COPY ./docker-images/.shared/dependencies/supercronic/gitman.yml /homelab/
COPY --from=gitconfig /root/.gitconfig /root/.gitconfig
RUN --mount=type=cache,target=/root/.gitcache,sharing=locked,id=homelab_gitman_gitcache \
    retry --times=3 -- gitman install --quiet && \
    find '.' -type d -name .git -prune -exec rm -rf {} \;

FROM golang:1.27.1-trixie AS supercronic_build
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_supercronic_build_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_supercronic_build_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=supercronic_gitman /homelab/gitman-repositories/supercronic/ ./supercronic/
ENV CGO_ENABLED="0"
WORKDIR /homelab/supercronic
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    go build -ldflags='-s -w -buildid=' -buildvcs=false && \
    strip --strip-all supercronic
WORKDIR /homelab
COPY ./docker-images/.shared/build-utils/validate-executable.sh /homelab/
RUN sh validate-executable.sh ./supercronic/supercronic

### Healthcheck ###

FROM golang:1.27.1-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/filecmp-healthcheck/main.go ./docker-images/.shared/healthchecks/filecmp-healthcheck/go.mod ./docker-images/.shared/healthchecks/filecmp-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Other ###

FROM debian:13.7-slim AS package_ca_certificates
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_package_ca_certificates_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_package_ca_certificates_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates >/dev/null && \
    rm -rf /var/lib/apt/lists/*

FROM debian:13.7-slim AS package_curl
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_package_curl_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_package_curl_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        curl >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /homelab/usr-lib && \
    find /usr/lib \( -name 'libbrotli*' -or -name 'libcom*' -or -name 'libcurl*' -or -name 'libffi*' -or -name 'libgnutls*' -or -name 'libgssapi*' -or -name 'libidn*' -or -name 'libk*crypto*' -or -name 'libkeyutils*' -or -name 'libkrb*' -or -name 'liblber*' -or -name 'libldap*' -or -name 'libnghttp*' -or -name 'libp*kit*' -or -name 'libpsl*' -or -name 'librtmp*' -or -name 'libsasl*' -or -name 'libssh*' -or -name 'libtasn*' -or -name 'libunistring*' \) -exec sh -c 'mkdir -p "/homelab/usr-lib/$(dirname "$0" | sed -E "s~^/usr/lib/~~")" && cp "$0" "/homelab/usr-lib/$(dirname "$0" | sed -E "s~^/usr/lib/~~")/$(basename "$0")"' {} \;

FROM debian:13.7-slim AS empty_dir
USER root
RUN mkdir /empty

### Users ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

FROM debian:13.7-slim AS user_setup
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
COPY --from=empty_dir /empty /homelab/certs
COPY --from=empty_dir /empty /homelab/logs
COPY ./docker-images/.shared/cron-utils/cron-wrapper.sh ./docker-images/.shared/cron-utils/entrypoint.sh /homelab/
COPY ./docker-images/certbot/crontab.cron ./docker-images/certbot/main.sh ./docker-images/certbot/certbot-hook-after.sh ./docker-images/certbot/certbot-hook-before.sh /homelab/
COPY --from=supercronic_build /homelab/supercronic/supercronic /homelab/bin/
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=package_ca_certificates /etc/ssl/certs/ca-certificates.crt /fsroot/certs/
COPY --from=package_curl /usr/bin/curl /fsroot/usr-bin/
COPY --from=package_curl /homelab/usr-lib/ /fsroot/usr-lib/

### Final ###

FROM debian:13.7-slim
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_certbot_final_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_certbot_final_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        certbot jq xz-utils >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/certs /etc/ssl/certs
COPY --from=prefinal --chown=homelab:homelab /fsroot/usr-bin/ /usr/bin/
COPY --from=prefinal --chown=homelab:homelab /fsroot/usr-lib/ /usr/lib/
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME="certbot" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PATH="/homelab/bin:${PATH}" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=120s --timeout=1s --retries=1 CMD [ "/homelab/bin/healthcheck", "--file", "/homelab/tmpfs/status.txt", "--content", "started" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
