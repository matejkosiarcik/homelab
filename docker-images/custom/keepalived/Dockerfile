# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM debian:12.8-slim
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends \
        keepalived moreutils iproute2 dnsutils && \
    rm -rf /var/lib/apt/lists/*
COPY ./custom/keepalived/entrypoint.sh ./
COPY ./custom/keepalived/keepalived.conf /etc/keepalived/keepalived.conf
HEALTHCHECK --interval=5s --start-period=60s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /homelab/.internal/status.txt /dev/stdin >/dev/null 2>&1 || exit 1" ]
ENTRYPOINT ["sh", "/homelab/entrypoint.sh"]
