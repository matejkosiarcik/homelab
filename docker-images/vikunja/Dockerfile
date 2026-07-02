# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### App ###

FROM vikunja/vikunja:0.24.6 AS vikunja-app
USER root

### Other ###

FROM debian:13.5-slim AS package-ca-certificates
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=vikunja-package-ca-certificates-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=vikunja-package-ca-certificates-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates >/dev/null && \
    rm -rf /var/lib/apt/lists/*

FROM debian:13.5-slim AS empty-dir
USER root
RUN mkdir /empty

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.5-slim AS user-setup
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
COPY --from=empty-dir /empty /homelab/logs

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY ./vikunja/config.yml /etc/vikunja/config.yml
COPY --from=vikunja-app /app /app
COPY --from=package-ca-certificates /etc/ssl/certs/ca-certificates.crt /fsroot/certs/

### Final ###

FROM scratch
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /etc/vikunja/config.yml /etc/vikunja/config.yml
COPY --from=prefinal --chown=homelab:homelab /app /app
COPY --from=prefinal --chown=homelab:homelab /fsroot/certs /etc/ssl/certs
ENV HOMELAB_CONTAINER_NAME=vikunja \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
WORKDIR /app/vikunja
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "./vikunja", "user", "list" ]
ENTRYPOINT [ "/app/vikunja/vikunja" ]
