# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM linuxserver/speedtest-tracker:1.6.2
ENV APP_TIMEZONE=Etc/Utc \
    DASHBOARD_POLLING=5s \
    DB_CONNECTION=sqlite \
    DISPLAY_TIMEZONE=Europe/Bratislava \
    FORCE_HTTPS=true \
    HOMELAB_CONTAINER_NAME=speedtest-tracker \
    HOMELAB_CONTAINER_VARIANT=default \
    MAIL_FROM_ADDRESS=system@speedtest-tracker.matejhome.com \
    MAIL_FROM_NAME=Speedtest-Tracker \
    MAIL_HOST=smtp4dev.matejhome.com \
    MAIL_MAILER=smtp \
    MAIL_PORT=25 \
    MAIL_SCHEME= \
    NOTIFICATION_POLLING=5s \
    PGID=1000 \
    PUBLIC_DASHBOARD=true \
    PUID=1000 \
    RESULTS_POLLING=5s \
    SPEEDTEST_SCHEDULE="15 */4 * * *" \
    TZ=Etc/Utc
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --insecure --fail https://localhost/api/healthcheck || exit 1" ]
