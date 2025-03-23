# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM nicolargo/glances:4.3.1-full
RUN mkdir /homelab
COPY ./external/glances/glances.conf /homelab/glances.conf
ENV HOMELAB_CONTAINER_NAME=glances \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl http://localhost:61208 || exit 1" ]
