# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### App ###

FROM vikunja/vikunja:2.6.0 AS vikunja_app
USER root

### Other ###

FROM debian:13.7-slim AS package_ca_certificates
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_package_ca_certificates_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_package_ca_certificates_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates >/dev/null && \
    rm -rf /var/lib/apt/lists/*

FROM debian:13.7-slim AS empty_dir
USER root
RUN mkdir /empty

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
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab
COPY --from=empty_dir /empty /homelab/logs

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY ./docker-images/vikunja/config.yml /etc/vikunja/config.yml
COPY --from=vikunja_app /app /app
COPY --from=package_ca_certificates /etc/ssl/certs/ca-certificates.crt /fsroot/certs/

### Final ###

FROM scratch
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /etc/vikunja/config.yml /etc/vikunja/config.yml
COPY --from=prefinal --chown=homelab:homelab /app /app
COPY --from=prefinal --chown=homelab:homelab /fsroot/certs /etc/ssl/certs
ENV HOMELAB_CONTAINER_NAME="vikunja" \
    HOMELAB_CONTAINER_VARIANT="default" \
    TZ="Europe/Bratislava"
WORKDIR /app/vikunja
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "./vikunja", "user", "list" ]
ENTRYPOINT [ "/app/vikunja/vikunja" ]
