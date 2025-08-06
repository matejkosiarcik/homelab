# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM debian:12.11-slim
WORKDIR /homelab
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        dnsutils unbound >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./external/unbound/entrypoint.sh ./entrypoint.sh
COPY ./external/unbound/config ./config
ENV HOMELAB_CONTAINER_NAME=unbound \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "dig @127.0.0.1 +short placeholder.matejhome.com || exit 1" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
