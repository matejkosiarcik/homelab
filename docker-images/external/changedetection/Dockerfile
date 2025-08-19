# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM dgtlmoon/changedetection.io:0.50.10
COPY ./external/changedetection/healthcheck.py /homelab/
ENV FETCH_WORKERS=4 \
    HOMELAB_CONTAINER_NAME=changedetection \
    HOMELAB_CONTAINER_VARIANT=default \
    LOGGER_LEVEL=WARNING \
    TZ=Europe/Bratislava \
    PLAYWRIGHT_DRIVER_URL=ws://sockpuppetbrowser:3000
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "python3 /homelab/healthcheck.py || exit 1" ]
