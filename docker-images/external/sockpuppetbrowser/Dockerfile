# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM dgtlmoon/sockpuppetbrowser:0.0.3
ENV ALLOW_CDP_LOG=no \
    CHROME_USER_DATA_DIR=/homelab/chrome-user-data \
    HOMELAB_CONTAINER_NAME=socket-proxy \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=30s --timeout=5s CMD [ "sh", "-c", "python3 /usr/src/app/docker-health-check.py --host http://localhost || exit 1" ]
