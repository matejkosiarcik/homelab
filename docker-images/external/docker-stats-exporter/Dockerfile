# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM wywywywy/docker_stats_exporter:20220516
ENV DOCKERSTATS_INTERVAL=60 \
    HOMELAB_CONTAINER_NAME=docker-registry \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "wget -O /dev/null http://localhost:9487 || exit 1" ]
