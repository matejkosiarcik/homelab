# syntax=docker/dockerfile:1

### Build config ###

FROM debian:13.2-slim AS gitconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=unbound-prometheus-exporter-gitconfig-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=unbound-prometheus-exporter-gitconfig-aptlibcache \
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
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked,id=unbound-prometheus-exporter-gitman-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet

FROM python:3.14.2-slim AS unbound-prometheus-exporter-gitman
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=unbound-prometheus-exporter-gitman-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=unbound-prometheus-exporter-gitman-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/python-vendor /homelab/python-vendor
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./external/unbound-prometheus-exporter/gitman.yml /homelab/
COPY --from=gitconfig /root/.gitconfig /root/.gitconfig
RUN --mount=type=cache,target=/root/.cache/git,sharing=locked,id=unbound-prometheus-exporter-gitman-gitcache \
    gitman install --quiet && \
    find . -type d -name .git -prune -exec rm -rf {} \;

### App ###

FROM golang:1.25.5-bookworm AS unbound-prometheus-exporter-build
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=unbound-prometheus-exporter-build-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=unbound-prometheus-exporter-build-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=unbound-prometheus-exporter-gitman /homelab/gitman-repositories/unbound_exporter/ /homelab/unbound_exporter/
ENV CGO_ENABLED=0
WORKDIR /homelab/unbound_exporter
RUN go build -ldflags='-s -w -buildid=' -buildvcs=false && \
    strip --strip-all unbound_exporter
WORKDIR /homelab
COPY ./.shared/build-utils/validate-executable.sh /homelab/
RUN sh validate-executable.sh ./unbound_exporter/unbound_exporter

### Healthcheck ###

FROM golang:1.25.5-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/http-healthcheck/main.go ./.shared/healthchecks/http-healthcheck/go.mod ./.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=unbound-prometheus-exporter-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=unbound-prometheus-exporter-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Other ###

FROM busybox:1.35.0-uclibc AS busybox

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
COPY ./external/unbound-prometheus-exporter/entrypoint.sh /homelab/entrypoint.sh
COPY --from=unbound-prometheus-exporter-build /homelab/unbound_exporter/unbound_exporter /homelab/bin/
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY --from=busybox /bin/arch /bin/awk /bin/base64 /bin/basename /bin/bc /bin/cat /bin/cmp /bin/comm /bin/cp /bin/crc32 /bin/cut /bin/date /bin/dd /bin/diff /bin/dirname /bin/echo /bin/egrep /bin/env /bin/expand /bin/false /bin/fgrep /bin/find /bin/flock /bin/fsync /bin/getopt /bin/grep /bin/gunzip /bin/gzip /bin/head /bin/kill /bin/ln /bin/ls /bin/md5sum /bin/mkdir /bin/mkfifo /bin/mv /bin/nohup /bin/nproc /bin/patch /bin/printenv /bin/printf /bin/pwd /bin/realpath /bin/rm /bin/rmdir /bin/sed /bin/sed /bin/seq /bin/sh /bin/sha1sum /bin/sha256sum /bin/sha3sum /bin/sha512sum /bin/sleep /bin/sort /bin/tail /bin/tar /bin/tee /bin/time /bin/timeout /bin/touch /bin/tr /bin/true /bin/uname /bin/unexpand /bin/uniq /bin/unzip /bin/watch /bin/wc /bin/wc /bin/which /bin/xargs /bin/xz /bin/yes /build/fsroot/bin/

### Final ###

FROM gcr.io/distroless/base-debian13
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /build/fsroot/bin/ /bin/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME=unbound-prometheus-exporter \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="/homelab/bin:$PATH" \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:9167/metrics" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
