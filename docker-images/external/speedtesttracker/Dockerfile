# checkov:skip=CKV_DOCKER_3: USER can't be set directly, but it should be used after container initialized

FROM linuxserver/speedtest-tracker:1.6.8
ARG UID=1000
ARG GID=1000
RUN apk update --no-cache && \
    apk add --no-cache shadow && \
    if [ "$(getent group "$GID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
        groupadd --gid "$GID" homelab && \
    true; else \
        oldgroupname="$(getent group "$GID" | cut -d: -f1)" && \
        groupmod --new-name homelab "$oldgroupname" && \
    true; fi && \
    nologinshell='' && \
    if [ -e /sbin/nologin ]; then \
        nologinshell='/sbin/nologin' && \
    true; elif [ -e /usr/sbin/nologin ]; then \
        nologinshell='/usr/sbin/nologin' && \
    true; else \
        nologinshell='/bin/false' && \
    true; fi && \
    if [ "$(getent passwd "$UID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
        useradd --no-log-init --home /home/homelab --uid "$UID" --gid "$GID" --shell "$nologinshell" homelab && \
    true; else \
        oldusername="$(getent passwd "$UID" | cut -d: -f1)" && \
        usermod --move-home --home /home/homelab --uid "$UID" --gid "$GID" --shell "$nologinshell" --login homelab "$oldusername" && \
    true; fi && \
    apk del --no-cache shadow && \
    mkdir -p /home/homelab /homelab && \
    chown -R homelab:homelab /home/homelab /homelab /app/www
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
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --insecure --fail https://localhost/api/healthcheck || exit 1" ]
