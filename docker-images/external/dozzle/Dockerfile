# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM amir20/dozzle:v8.12.3
ENV DOZZLE_AUTH_PROVIDER=simple \
    DOZZLE_HOSTNAME=Server \
    DOZZLE_ENABLE_ACTIONS=false \
    HOMELAB_CONTAINER_NAME=dozzle \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=20s --timeout=2s --retries=1 CMD [ "/dozzle", "healthcheck" ]
