# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in
# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM vaultwarden/server:1.34.1
ENV EXTENDED_LOGGING=true \
    HOMELAB_CONTAINER_NAME=vaultwarden \
    HOMELAB_CONTAINER_VARIANT=default \
    LOG_FILE=/homelab/logs/vaultwarden.log \
    LOG_LEVEL=error \
    LOG_LEVEL=warn \
    PASSWORD_ITERATIONS=500000 \
    SENDS_ALLOWED=true \
    SIGNUPS_ALLOWED=false \
    SIGNUPS_VERIFY=true \
    SMTP_FROM_NAME=Vaultwarden \
    SMTP_HOST=smtp4dev.matejhome.com \
    SMTP_PORT=25 \
    SMTP_SECURITY=off \
    SMTP_TIMEOUT=10 \
    TZ=Europe/Bratislava \
    WEBSOCKET_ENABLED=true

# TODO: Set SMTP authentication: SMTP_SECURITY, SMTP_USERNAME, SMTP_PASSWORD
