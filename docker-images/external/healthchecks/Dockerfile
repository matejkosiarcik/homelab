# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM debian:12.7-slim AS prefinal
WORKDIR /homelab
RUN mkdir -p ./healthchecks
COPY ./external/healthchecks/healthcheck.py ./healthcheck.py

FROM healthchecks/healthchecks:v3.6
COPY --from=prefinal /homelab /homelab
COPY ./external/healthchecks/icons/healthchecks.png /opt/healthchecks/static-collected/img/custom-healthchecks.png
ENV DB=sqlite \
    DB_NAME=/homelab/healthchecks/database.db \
    DEBUG=False \
    HOMELAB_CONTAINER_NAME=healthchecks \
    HOMELAB_CONTAINER_VARIANT=default \
    INTEGRATIONS_ALLOW_PRIVATE_IPS=True \
    PROMETHEUS_ENABLED=True \
    REGISTRATION_OPEN=False \
    SITE_LOGO_URL=/static/img/custom-healthchecks.png \
    TZ=Europe/Bratislava

# TODO: Enable email integration
# TODO: EMAIL_HOST ???
# EMAIL_HOST_PASSWORD= # TODO: Set ?
# EMAIL_HOST_USER= # TODO: Set ?
# EMAIL_PORT=8025 # TODO: Unset
# EMAIL_USE_SSL=False # TODO: Remove
# EMAIL_USE_TLS=False # TODO: Set True
# EMAIL_USE_VERIFICATION=True \

HEALTHCHECK --interval=5s --start-period=20s --timeout=2s --retries=1 CMD [ "sh", "-c", "python3 /homelab/healthcheck.py || exit 1" ]
