# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM debian:12.7-slim
WORKDIR /homelab
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        socat >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./custom/socket-proxy/entrypoint.sh ./
ENV HOMELAB_CONTAINER_NAME=socket-proxy \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=10s --timeout=1s CMD [ "sh", "-c", "printf 'started\n' | cmp /homelab/.internal/status.txt /dev/stdin >/dev/null 2>&1 || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
