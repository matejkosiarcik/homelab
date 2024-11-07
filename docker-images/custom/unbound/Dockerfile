# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM debian:12.7-slim
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends \
        curl dnsutils unbound && \
    rm -rf /var/lib/apt/lists/*
COPY ./custom/unbound/unbound.conf /etc/unbound/
ENV HOMELAB_CONTAINER_NAME=unbound \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "nslookup example.com localhost || exit 1" ]
ENTRYPOINT [ "unbound", "-d", "-v", "-c", "/etc/unbound/unbound.conf" ]
