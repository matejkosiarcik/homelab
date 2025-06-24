# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM prom/node-exporter:v1.9.1
ENV HOMELAB_CONTAINER_NAME=node_exporter \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "wget -O /dev/null http://localhost:9100 || exit 1" ]
CMD [ "--path.rootfs=/host" ]
