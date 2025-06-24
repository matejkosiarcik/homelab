# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM linuxserver/socket-proxy:3.2.1
RUN apk update --no-cache && \
    apk add --no-cache bash
ENV ALLOW_RESTARTS=0 \
    ALLOW_START=0 \
    ALLOW_STOP=0 \
    AUTH=0 \
    BUILD=0 \
    COMMIT=0 \
    CONFIGS=0 \
    CONTAINERS=0 \
    DISABLE_IPV6=0 \
    DISTRIBUTION=0 \
    EVENTS=0 \
    EXEC=0 \
    HOMELAB_CONTAINER_NAME=socket-proxy \
    HOMELAB_CONTAINER_VARIANT=default \
    IMAGES=0 \
    INFO=0 \
    LOG_LEVEL=info \
    NETWORKS=0 \
    NODES=0 \
    PING=0 \
    PLUGINS=0 \
    POST=0 \
    SECRETS=0 \
    SERVICES=0 \
    SESSION=0 \
    SWARM=0 \
    SYSTEM=0 \
    TASKS=0 \
    TZ=Europe/Bratislava \
    VERSION=0 \
    VOLUMES=0
VOLUME /var/run/docker.sock
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "bash -c ':> /dev/tcp/localhost/2375' || exit 1" ]
