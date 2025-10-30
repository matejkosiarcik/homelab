FROM ghcr.io/seanmorley15/adventurelog-backend:v0.11.0
ARG UID=1000
ARG GID=1000
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
    ln -sf /run/supervisord.pid /code/supervisord.pid && \
    ln -sf /run/supervisord.log /code/supervisord.log && \
    ln -sf /run/scheduler.log /code/scheduler.log && \
    chown -R homelab:homelab /code /home/homelab /homelab /var/log/nginx
COPY --chown=homelab:homelab ./external/adventurelog-backend/healthcheck.py /homelab/
ENV DEBUG=False \
    DISABLE_REGISTRATION=True \
    DJANGO_ADMIN_USERNAME=admin \
    EMAIL_BACKEND=email \
    EMAIL_HOST=smtp4dev.matejhome.com \
    EMAIL_PORT=25 \
    EMAIL_USE_SSL=False \
    EMAIL_USE_TLS=False \
    HOMELAB_CONTAINER_NAME=adventurelog \
    HOMELAB_CONTAINER_VARIANT=default \
    PGDATABASE=adventurelog \
    PGHOST=database \
    PGUSER=postgres \
    TZ=Europe/Bratislava
# Startup period a bit longer for initial migration - downloads stuff from github and sets up locations database
HEALTHCHECK --interval=10s --start-period=180s --timeout=2s --retries=1 CMD [ "sh", "-c", "python3 /homelab/healthcheck.py || exit 1" ]
USER homelab
