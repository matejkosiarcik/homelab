# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_8: Ignore root user

FROM debian:12.11-slim AS prefinal
WORKDIR /homelab
RUN mkdir -p ./healthchecks
COPY ./external/healthchecks/healthcheck.py ./healthcheck.py

FROM healthchecks/healthchecks:v3.10
COPY --from=prefinal /homelab /homelab
COPY ./external/healthchecks/icons/healthchecks.png /opt/healthchecks/static-collected/img/custom-healthchecks.png
ENV DB=sqlite \
    DB_NAME=/homelab/healthchecks/database.db \
    DEBUG=False \
    EMAIL_PORT=25 \
    EMAIL_USE_SSL=False \
    EMAIL_USE_TLS=False \
    HOMELAB_CONTAINER_NAME=healthchecks \
    HOMELAB_CONTAINER_VARIANT=default \
    INTEGRATIONS_ALLOW_PRIVATE_IPS=True \
    PROMETHEUS_ENABLED=True \
    REGISTRATION_OPEN=True \
    SITE_LOGO_URL=/static/img/custom-healthchecks.png \
    TZ=Europe/Bratislava

# TODO: Enable secure emails
# EMAIL_HOST_PASSWORD=
# EMAIL_HOST_USER=
# EMAIL_USE_SSL=False
# EMAIL_USE_TLS=True

# User is necessary in production
# hadolint ignore=DL3002
USER root

HEALTHCHECK --interval=5s --start-period=20s --timeout=2s --retries=1 CMD [ "sh", "-c", "python3 /homelab/healthcheck.py || exit 1" ]
