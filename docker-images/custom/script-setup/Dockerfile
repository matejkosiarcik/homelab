# syntax=docker/dockerfile:1

### Other ###

FROM debian:13.2-slim AS package-moreutils
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*

FROM busybox:1.35.0-uclibc AS busybox

### Healthcheck ###

FROM golang:1.25.5-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/filecmp-healthcheck/main.go ./.shared/healthchecks/filecmp-healthcheck/go.mod ./.shared/healthchecks/filecmp-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=private,id=script-setup-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=private,id=script-setup-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Users ###

FROM gcr.io/distroless/static-debian13 AS user-setup-base

FROM debian:13.2-slim AS user-setup
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
COPY --chown=homelab:homelab ./custom/script-setup/entrypoint.sh /homelab/
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY --from=busybox /bin/arch /bin/awk /bin/base64 /bin/basename /bin/bc /bin/cat /bin/cmp /bin/comm /bin/cp /bin/crc32 /bin/cut /bin/date /bin/dd /bin/diff /bin/dirname /bin/echo /bin/egrep /bin/env /bin/expand /bin/false /bin/fgrep /bin/find /bin/flock /bin/fsync /bin/getopt /bin/grep /bin/gunzip /bin/gzip /bin/head /bin/kill /bin/ln /bin/ls /bin/md5sum /bin/mkdir /bin/mkfifo /bin/mv /bin/nohup /bin/nproc /bin/patch /bin/printenv /bin/printf /bin/pwd /bin/realpath /bin/rm /bin/rmdir /bin/sed /bin/sed /bin/seq /bin/sh /bin/sha1sum /bin/sha256sum /bin/sha3sum /bin/sha512sum /bin/sleep /bin/sort /bin/tail /bin/tar /bin/tee /bin/time /bin/timeout /bin/touch /bin/tr /bin/true /bin/uname /bin/unexpand /bin/uniq /bin/unzip /bin/watch /bin/wc /bin/wc /bin/which /bin/xargs /bin/xz /bin/yes /build/bin/
COPY --from=package-moreutils /usr/bin/sponge /build/usr-bin/

### Final ###

FROM gcr.io/distroless/base-debian13
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /build/bin/ /bin/
COPY --from=prefinal --chown=homelab:homelab /build/usr-bin/ /usr/bin/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME=script-setup \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=90s --timeout=1s --retries=1 CMD [ "/homelab/bin/healthcheck", "--file", "/homelab/tmpfs/status.txt", "--content", "started" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
