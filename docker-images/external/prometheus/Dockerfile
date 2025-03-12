# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_8: Ignore root user

FROM prom/prometheus:v3.2.1
COPY ./external/prometheus/web.yml /etc/prometheus/web.yml
COPY ./external/prometheus/prometheus.yml /etc/prometheus/prometheus.yml
COPY ./external/prometheus/entrypoint.sh /etc/prometheus/entrypoint.sh
ENV HOMELAB_CONTAINER_NAME=prometheus \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "wget -O /dev/null http://admin:$PROMETHEUS_ADMIN_PASSWORD@localhost:9090 || exit 1" ]
# hadolint ignore=DL3002
USER root
ENTRYPOINT [ "sh", "/etc/prometheus/entrypoint.sh" ]
CMD []
