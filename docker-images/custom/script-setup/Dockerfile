# checkov:skip=CKV_DOCKER_3: No need for explicit user


FROM debian:12.11-slim
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends \
        moreutils && \
    rm -rf /var/lib/apt/lists/*
COPY ./custom/script-setup/entrypoint.sh /homelab/
ENV HOMELAB_CONTAINER_NAME=script-setup \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=90s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /homelab/.status/status.txt /dev/stdin >/dev/null 2>&1 || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
