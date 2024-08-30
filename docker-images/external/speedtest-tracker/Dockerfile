# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM linuxserver/speedtest-tracker:0.20.6
ENV \
    APP_TIMEZONE=Etc/Utc \
    DB_CONNECTION=sqlite \
    DISPLAY_TIMEZONE=Europe/Bratislava \
    FORCE_HTTPS=true \
    HOMELAB_CONTAINER_NAME=speedtest-tracker \
    HOMELAB_CONTAINER_VARIANT=default \
    PGID=1000 \
    PUID=1000 \
    TZ=Etc/Utc

HEALTHCHECK --interval=5s --start-period=30s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --insecure --fail https://localhost/api/healthcheck || exit 1" ]
