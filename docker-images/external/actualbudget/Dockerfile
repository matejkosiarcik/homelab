# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM actualbudget/actual-server:25.8.0
COPY ./external/actualbudget/healthcheck.js /homelab/
ENV ERR_ERL_UNEXPECTED_X_FORWARDED_FOR=false \
    HOMELAB_CONTAINER_NAME=actualbudget \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "node /homelab/healthcheck.js || exit 1" ]
