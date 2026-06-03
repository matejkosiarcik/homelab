# syntax=docker/dockerfile:1

### Build config ###

FROM debian:13.2-slim AS gitconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=minio-client-gitconfig-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=minio-client-gitconfig-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/anticache.txt /homelab/
RUN printf '' >/root/.gitconfig && \
    { curl --fail --silent https://git-cache-github.matejhome.com || exit 0; } && \
    git config --global url."https://git-cache-github.matejhome.com/".insteadOf "https://github.com/"

### Dependencies ###

FROM python:3.14.2-slim AS gitman
USER root
WORKDIR /homelab
COPY ./.shared/dependencies/gitman/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked,id=minio-client-gitman-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet

### Other ###

FROM debian:13.2-slim AS package-ca-certificates
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=minio-client-package-ca-certificates-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=minio-client-package-ca-certificates-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates >/dev/null && \
    rm -rf /var/lib/apt/lists/*

FROM debian:13.2-slim AS package-curl
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=minio-client-package-curl-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=minio-client-package-curl-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*

FROM busybox:1.35.0-uclibc AS busybox
USER root
COPY ./.shared/build-utils/busybox-copy.sh /homelab/
RUN sh /homelab/busybox-copy.sh

### App ###

FROM python:3.14.2-slim AS minio-mc-gitman
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=minio-client-minio-cli-gitman-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=minio-client-minio-cli-gitman-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/python-vendor /homelab/python-vendor
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./external/minio-client/gitman.yml /homelab/
COPY --from=gitconfig /root/.gitconfig /root/.gitconfig
RUN --mount=type=cache,target=/root/.cache/git,sharing=locked,id=minio-client-cli-gitman-gitcache \
    gitman install --quiet && \
    find . -type d -name .git -prune -exec rm -rf {} \;

FROM golang:1.25.5-bookworm AS minio-mc-build
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=minio-client-minio-cli-build-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=minio-client-minio-cli-build-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=minio-mc-gitman /homelab/gitman-repositories/minio-mc/ ./minio-mc/
ENV CGO_ENABLED=0
WORKDIR /homelab/minio-mc
RUN go build -ldflags='-s -w -buildid=' -buildvcs=false && \
    strip --strip-all mc
WORKDIR /homelab
COPY ./.shared/build-utils/validate-executable.sh /homelab/
RUN sh validate-executable.sh ./minio-mc/mc

### Healthcheck ###

FROM golang:1.25.5-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/filecmp-healthcheck/main.go ./.shared/healthchecks/filecmp-healthcheck/go.mod ./.shared/healthchecks/filecmp-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=minio-client-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=minio-client-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### User setup ###

FROM gcr.io/distroless/static-debian13 AS user-setup-base

FROM debian:13.2-slim AS user-setup
USER root
WORKDIR /homelab
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab
COPY ./external/minio-client/entrypoint.sh ./external/minio-client/main.sh ./external/minio-client/plain-buckets.txt ./external/minio-client/versioned-buckets.txt /homelab/
COPY --from=minio-mc-build /homelab/minio-mc/mc /homelab/bin/
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY --from=package-curl /usr/bin/curl /fsroot/usr-bin/
COPY --from=package-curl /usr/lib/ /fsroot/usr-lib/
COPY --from=package-ca-certificates /etc/ssl/certs/ca-certificates.crt /fsroot/certs/
COPY --from=busybox /fsroot/bin /fsroot/bin

### Final ###

FROM gcr.io/distroless/base-debian13
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/certs/ /etc/ssl/certs/
COPY --from=prefinal --chown=homelab:homelab /fsroot/bin/ /bin/
COPY --from=prefinal --chown=homelab:homelab /fsroot/usr-bin/ /usr/bin/
COPY --from=prefinal --chown=homelab:homelab /fsroot/usr-lib/ /usr/lib/
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME=certificator \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="/homelab/bin:$PATH" \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=1s --retries=1 CMD [ "/homelab/bin/healthcheck", "--file", "/homelab/tmpfs/status.txt", "--content", "started" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
