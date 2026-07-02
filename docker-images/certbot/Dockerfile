# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Build config ###

FROM debian:13.5-slim AS gitconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=certbot-gitconfig-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=certbot-gitconfig-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/anticache.txt /homelab/
RUN printf '' >/root/.gitconfig && \
    { curl --fail --silent https://git-cache-github.matejhome.com || exit 0; } && \
    git config --global url."https://git-cache-github.matejhome.com/".insteadOf "https://github.com/"

### Dependencies ###

FROM python:3.14.6-slim AS gitman
USER root
WORKDIR /homelab
COPY ./.shared/dependencies/gitman/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked,id=certbot-gitman-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet --resume-retries 1

### Supercronic ###

FROM python:3.14.6-slim AS supercronic-gitman
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=certbot-supercronic-gitman-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=certbot-supercronic-gitman-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/python-vendor /homelab/python-vendor
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./.shared/dependencies/supercronic/gitman.yml /homelab/
COPY --from=gitconfig /root/.gitconfig /root/.gitconfig
RUN --mount=type=cache,target=/root/.cache/git,sharing=locked,id=certbot-supercronic-gitman-gitcache \
    gitman install --quiet && \
    find . -type d -name .git -prune -exec rm -rf {} \;

FROM golang:1.26.4-trixie AS supercronic-build
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=certbot-supercronic-build-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=certbot-supercronic-build-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=supercronic-gitman /homelab/gitman-repositories/supercronic/ ./supercronic/
ENV CGO_ENABLED=0
WORKDIR /homelab/supercronic
RUN go build -ldflags='-s -w -buildid=' -buildvcs=false && \
    strip --strip-all supercronic
WORKDIR /homelab
COPY ./.shared/build-utils/validate-executable.sh /homelab/
RUN sh validate-executable.sh ./supercronic/supercronic

### Healthcheck ###

FROM golang:1.26.4-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/filecmp-healthcheck/main.go ./.shared/healthchecks/filecmp-healthcheck/go.mod ./.shared/healthchecks/filecmp-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=certbot-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=certbot-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Other ###

FROM debian:13.5-slim AS package-ca-certificates
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=certbot-package-ca-certificates-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=certbot-package-ca-certificates-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates >/dev/null && \
    rm -rf /var/lib/apt/lists/*

FROM debian:13.5-slim AS package-curl
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=certificator-package-curl-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=certificator-package-curl-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        curl >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /homelab/usr-lib && \
    find /usr/lib \( -name 'libbrotli*' -or -name 'libcom*' -or -name 'libcurl*' -or -name 'libffi*' -or -name 'libgnutls*' -or -name 'libgssapi*' -or -name 'libidn*' -or -name 'libk*crypto*' -or -name 'libkeyutils*' -or -name 'libkrb*' -or -name 'liblber*' -or -name 'libldap*' -or -name 'libnghttp*' -or -name 'libp*kit*' -or -name 'libpsl*' -or -name 'librtmp*' -or -name 'libsasl*' -or -name 'libssh*' -or -name 'libtasn*' -or -name 'libunistring*' \) -exec sh -c 'mkdir -p "/homelab/usr-lib/$(dirname "$0" | sed -E "s~^/usr/lib/~~")" && cp "$0" "/homelab/usr-lib/$(dirname "$0" | sed -E "s~^/usr/lib/~~")/$(basename "$0")"' {} \;

FROM debian:13.5-slim AS empty-dir
USER root
RUN mkdir /empty

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
USER root
WORKDIR /homelab
COPY --from=empty-dir /empty /homelab/certs
COPY --from=empty-dir /empty /homelab/logs
COPY ./.shared/cron-utils/cron-wrapper.sh ./.shared/cron-utils/entrypoint.sh /homelab/
COPY ./certbot/crontab.cron ./certbot/main.sh ./certbot/certbot-hook-after.sh ./certbot/certbot-hook-before.sh /homelab/
COPY --from=supercronic-build /homelab/supercronic/supercronic /homelab/bin/
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY --from=package-ca-certificates /etc/ssl/certs/ca-certificates.crt /fsroot/certs/
COPY --from=package-curl /usr/bin/curl /fsroot/usr-bin/
COPY --from=package-curl /homelab/usr-lib/ /fsroot/usr-lib/

### Final ###

FROM debian:13.5-slim
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=certbot-final-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=certbot-final-aptlibcache \
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
ENV HOMELAB_CONTAINER_NAME=certbot \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="/homelab/bin:$PATH" \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=1s --retries=1 CMD [ "/homelab/bin/healthcheck", "--file", "/homelab/tmpfs/status.txt", "--content", "started" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
