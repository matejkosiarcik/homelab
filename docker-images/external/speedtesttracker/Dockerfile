# checkov:skip=CKV_DOCKER_8: Must run as root initially, and the linuxserver.io image switches to nonroot after it starts

### User setup ###

FROM gcr.io/distroless/static-debian13 AS user-setup-base

FROM debian:13.2-slim AS user-setup
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh && \
    cat /etc/group | grep -E '^homelab:' | sed 's~^homelab~abc~' | sponge --append /etc/group && \
    cat /etc/passwd | grep -E '^homelab:' | sed 's~^homelab~abc~' | sponge --append /etc/passwd

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

FROM linuxserver/speedtest-tracker:1.13.3
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
RUN chown -R homelab:homelab /app/www
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
ARG GID=1000
ARG UID=1000
ENV APP_TIMEZONE=Etc/Utc \
    DASHBOARD_POLLING=5s \
    DB_CONNECTION=sqlite \
    DISPLAY_TIMEZONE=Europe/Bratislava \
    FORCE_HTTPS=true \
    HOMELAB_CONTAINER_NAME=speedtesttracker \
    HOMELAB_CONTAINER_VARIANT=default \
    MAIL_FROM_ADDRESS=speedtesttracker@matejhome.com \
    MAIL_FROM_NAME=Speedtest-Tracker \
    MAIL_HOST=smtp4dev.matejhome.com \
    MAIL_MAILER=smtp \
    MAIL_PORT=25 \
    MAIL_SCHEME= \
    NOTIFICATION_POLLING=5s \
    PGID=$GID \
    PUBLIC_DASHBOARD=false \
    PUID=$UID \
    RESULTS_POLLING=5s \
    SPEEDTEST_SCHEDULE="15 */4 * * *" \
    TZ=Etc/Utc
# TODO: Consider:
# CACHE_STORE=file \
# APP_DEBUG=true \
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "curl --insecure --fail https://localhost/api/healthcheck || exit 1" ]
