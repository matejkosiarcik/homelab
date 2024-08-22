# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM debian:12.6-slim
WORKDIR /app
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends ncat socat >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./custom/socket-proxy/entrypoint.sh ./
ENV HOMELAB_CONTAINER_TYPE=socket-proxy \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=10s --timeout=1s CMD [ "sh", "-c", "printf 'started\n' | cmp /app/.internal/status /dev/stdin >/dev/null 2>&1 || exit 1" ]
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
