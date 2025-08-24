# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM bitnami/apache-exporter:1.0.10
ARG UID
ARG GID
USER root
RUN groupadd -g $GID user && \
    useradd -m -u $UID -g $GID user
USER user
WORKDIR /homelab
COPY --chown=user:user ./external/apache-prometheus-exporter/entrypoint.sh ./
ENV HOMELAB_CONTAINER_NAME=apache-prometheus-exporter \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "bash -c ':> /dev/tcp/localhost/9117' || exit 1"  ]
