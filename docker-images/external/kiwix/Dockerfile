# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM ghcr.io/kiwix/kiwix-serve:3.7.0
COPY ./external/kiwix/entrypoint.sh /homelab/entrypoint.sh
ENV HOMELAB_CONTAINER_NAME=kiwix \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "wget -O /dev/null http://localhost:8080 || exit 1" ]
