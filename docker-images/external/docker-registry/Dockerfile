# syntax=docker/dockerfile:1

### App ###

FROM registry:3.0.0 AS docker-registry-app
USER root

### Healthcheck ###

FROM golang:1.25.5-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/http-healthcheck/main.go ./.shared/healthchecks/http-healthcheck/go.mod ./.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=docker-registry-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=docker-registry-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Other ###

FROM busybox:1.35.0-uclibc AS busybox

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
WORKDIR /homelab
COPY ./external/docker-registry/config.yml ./external/docker-registry/entrypoint.sh /homelab/
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY --from=docker-registry-app /bin/registry /build/fsroot/bin/
COPY --from=busybox /bin/arch /bin/awk /bin/base64 /bin/basename /bin/bc /bin/cat /bin/cmp /bin/comm /bin/cp /bin/crc32 /bin/cut /bin/date /bin/dd /bin/diff /bin/dirname /bin/echo /bin/egrep /bin/env /bin/expand /bin/false /bin/fgrep /bin/find /bin/flock /bin/fsync /bin/getopt /bin/grep /bin/gunzip /bin/gzip /bin/head /bin/kill /bin/ln /bin/ls /bin/md5sum /bin/mkdir /bin/mkfifo /bin/mv /bin/nohup /bin/nproc /bin/patch /bin/printenv /bin/printf /bin/pwd /bin/realpath /bin/rm /bin/rmdir /bin/sed /bin/sed /bin/seq /bin/sh /bin/sha1sum /bin/sha256sum /bin/sha3sum /bin/sha512sum /bin/sleep /bin/sort /bin/tail /bin/tar /bin/tee /bin/time /bin/timeout /bin/touch /bin/tr /bin/true /bin/uname /bin/unexpand /bin/uniq /bin/unzip /bin/watch /bin/wc /bin/wc /bin/which /bin/xargs /bin/xz /bin/yes /build/fsroot/bin/

### Final ###

FROM gcr.io/distroless/static-debian13
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /build/fsroot/bin/ /bin/
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME=docker-registry \
    HOMELAB_CONTAINER_VARIANT=default \
    OTEL_TRACES_EXPORTER=none \
    TZ=Europe/Bratislava
# TODO: Eventually enable OpenTelemetry
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost" ]
USER homelab
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
