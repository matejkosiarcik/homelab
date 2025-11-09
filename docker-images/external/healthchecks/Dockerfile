# checkov:skip=CKV_DOCKER_8: Ignore root user

FROM debian:13.1-slim AS prefinal
WORKDIR /homelab
RUN mkdir -p ./healthchecks
COPY ./external/healthchecks/healthcheck.py ./healthcheck.py

FROM healthchecks/healthchecks:v3.11.2
ARG GID=1000
ARG UID=1000
USER root
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
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --chown=homelab:homelab ./external/healthchecks/icons/healthchecks.png /opt/healthchecks/static-collected/img/custom-healthchecks.png
ENV DB=sqlite \
    DB_NAME=/homelab/healthchecks/database.db \
    DEBUG=False \
    EMAIL_HOST=smtp4dev.matejhome.com \
    EMAIL_PORT=25 \
    EMAIL_USE_SSL=False \
    EMAIL_USE_TLS=False \
    HOMELAB_CONTAINER_NAME=healthchecks \
    HOMELAB_CONTAINER_VARIANT=default \
    INTEGRATIONS_ALLOW_PRIVATE_IPS=True \
    PROMETHEUS_ENABLED=True \
    REGISTRATION_OPEN=False \
    SHELL_ENABLED=False \
    SITE_LOGO_URL=/static/img/custom-healthchecks.png \
    TZ=Europe/Bratislava
# TODO: Enable secure emails
# EMAIL_HOST_PASSWORD=
# EMAIL_HOST_USER=
# EMAIL_USE_SSL=False
# EMAIL_USE_TLS=True
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "python3 /homelab/healthcheck.py || exit 1" ]
USER homelab
