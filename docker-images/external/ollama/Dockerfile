# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM ollama/ollama:0.11.5
COPY ./external/ollama/entrypoint.sh /homelab/
ENV HOMELAB_CONTAINER_NAME=ollama \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=5s --retries=1 CMD [ "sh", "-c", "bash -c ':> /dev/tcp/localhost/11434' || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
