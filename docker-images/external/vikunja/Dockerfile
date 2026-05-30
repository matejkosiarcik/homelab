### App ###

FROM vikunja/vikunja:0.24.6 AS vikunja-app
USER root

### Other ###

FROM debian:13.2-slim AS certificates
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates >/dev/null && \
    rm -rf /var/lib/apt/lists/*

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

FROM debian:13.2-slim AS homelab-dir
WORKDIR /homelab
RUN mkdir -p ./logs

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=certificates /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY ./external/vikunja/config.yml /etc/vikunja/config.yml
COPY --from=vikunja-app /app /app

### Final ###

FROM scratch
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /etc/ssl/certs /etc/ssl/certs
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /etc/vikunja/config.yml /etc/vikunja/config.yml
COPY --from=prefinal --chown=homelab:homelab /app /app
ENV HOMELAB_CONTAINER_NAME=vikunja \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
WORKDIR /app/vikunja
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "./vikunja", "user", "list" ]
ENTRYPOINT [ "/app/vikunja/vikunja" ]
