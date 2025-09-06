# checkov:skip=CKV_DOCKER_3: USER can't be set directly, but it should be used after container initialized

FROM linuxserver/speedtest-tracker:1.6.6
RUN apk update --no-cache && \
    apk add --no-cache shadow
ARG UID=1000
ARG GID=1000
RUN ( addgroup -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( adduser -D -u "$UID" -G user user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    chown -R user:user /app/www
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
