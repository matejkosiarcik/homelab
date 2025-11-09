# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in

FROM vaultwarden/server:1.34.3
ARG GID=1000
ARG UID=1000
RUN if [ "$(getent group "$GID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
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
    mkdir -p /home/homelab /homelab && \
    chown -R homelab:homelab /home/homelab /homelab
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
USER homelab

# TODO: Set SMTP authentication: SMTP_SECURITY, SMTP_USERNAME, SMTP_PASSWORD
