FROM ekofr/pihole-exporter:v1.2.0 AS pihole-exporter

FROM debian:13.0-slim
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
ARG UID=1000
ARG GID=1000
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab && \
    chown -R user:user /homelab
COPY --from=pihole-exporter --chown=user:user /root/pihole-exporter /homelab/pihole-exporter
ENV HOMELAB_CONTAINER_NAME=pihole-prometheus-exporter \
    HOMELAB_CONTAINER_VARIANT=default \
    PIHOLE_PROTOCOL=http \
    TZ=Europe/Bratislava
USER user
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl http://localhost:9617 || exit 1" ]
ENTRYPOINT [ "/homelab/pihole-exporter" ]
CMD []
