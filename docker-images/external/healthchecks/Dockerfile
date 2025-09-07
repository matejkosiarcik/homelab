# checkov:skip=CKV_DOCKER_8: Ignore root user

FROM debian:13.0-slim AS prefinal
WORKDIR /homelab
RUN mkdir -p ./healthchecks
COPY ./external/healthchecks/healthcheck.py ./healthcheck.py

FROM healthchecks/healthchecks:v3.11.2
ARG UID=1000
ARG GID=1000
USER root
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" )
COPY --from=prefinal --chown=user:user /homelab /homelab
COPY --chown=user:user ./external/healthchecks/icons/healthchecks.png /opt/healthchecks/static-collected/img/custom-healthchecks.png
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
USER user
