# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM docker:28.3.0
COPY ./custom/docker-setup/entrypoint.sh /homelab/
ENV HOMELAB_CONTAINER_NAME=docker-setup \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=90s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /homelab/.internal/status.txt /dev/stdin >/dev/null 2>&1 || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
