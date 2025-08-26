FROM bitnami/apache-exporter:1.0.10
ARG UID=999
ARG GID=999
USER root
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab && \
    chown -R user:user /homelab
WORKDIR /homelab
COPY --chown=user:user ./external/apache-prometheus-exporter/entrypoint.sh ./
ENV HOMELAB_CONTAINER_NAME=apache-prometheus-exporter \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER user
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "bash -c ':> /dev/tcp/localhost/9117' || exit 1"  ]
