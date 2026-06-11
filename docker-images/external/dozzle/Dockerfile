# syntax=docker/dockerfile:1

### App ###

FROM amir20/dozzle:v8.14.12 AS dozzle-app
USER root

### Users ###

FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.5-slim AS user-setup
USER root
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Other ###

FROM debian:13.5-slim AS package-ca-certificates
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apache-prometheus-exporter-package-ca-certificates-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apache-prometheus-exporter-package-ca-certificates-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates >/dev/null && \
    rm -rf /var/lib/apt/lists/*

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY --from=dozzle-app /dozzle /dozzle
COPY --from=dozzle-app /data /data
COPY --from=package-ca-certificates /etc/ssl/certs/ca-certificates.crt /fsroot/certs/

### Final ###

FROM scratch
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /dozzle /dozzle
COPY --from=prefinal --chown=homelab:homelab /data /data
COPY --from=prefinal --chown=homelab:homelab /fsroot/certs /etc/ssl/certs
ENV DOZZLE_AUTH_PROVIDER=simple \
    DOZZLE_ENABLE_ACTIONS=false \
    DOZZLE_HOSTNAME=Server \
    DOZZLE_REMOTE_AGENT=dozzle-agent-odroid-h3.matejhome.com:7007,dozzle-agent-odroid-h4-ultra.matejhome.com:7007,dozzle-agent-raspberry-pi-4b-2g.matejhome.com:7007,dozzle-agent-raspberry-pi-4b-4g.matejhome.com:7007 \
    HOMELAB_CONTAINER_NAME=dozzle \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=20s --timeout=2s --retries=1 CMD [ "/dozzle", "healthcheck" ]
ENTRYPOINT [ "/dozzle" ]
