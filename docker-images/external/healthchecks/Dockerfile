# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM healthchecks/healthchecks:v3.5.2
COPY ./external/healthchecks/healthcheck.py /.homelab/healthcheck.py
ENV DB_NAME=database \
    DB=postgres \
    DEBUG=False \
    HOMELAB_CONTAINER_NAME=healthchecks \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava

# TODO: Enable email integration
# TODO: EMAIL_HOST ???
# EMAIL_HOST_PASSWORD= # TODO: Set ?
# EMAIL_HOST_USER= # TODO: Set ?
# EMAIL_PORT=8025 # TODO: Unset
# EMAIL_USE_SSL=False # TODO: Remove
# EMAIL_USE_TLS=False # TODO: Set True
# EMAIL_USE_VERIFICATION=True \

HEALTHCHECK --interval=5s --start-period=20s --timeout=2s --retries=1 CMD [ "sh", "-c", "python3 /.homelab/healthcheck.py || exit 1" ]
