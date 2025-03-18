# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM debian:12.10-slim
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends \
        gnutls-bin samba moreutils && \
    rm -rf /var/lib/apt/lists/*
COPY ./external/samba/smb.conf /etc/samba/smb.conf
COPY ./external/samba/entrypoint.sh ./
ENV HOMELAB_CONTAINER_NAME=samba \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "bash -c ':> /dev/tcp/localhost/139' || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
