FROM debian:13.0-slim
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        dnsutils libcap2-bin unbound >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    setcap 'cap_net_bind_service=+ep' "$(which unbound)"
ARG UID=1999
ARG GID=1999
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab && \
    chown -R user:user /homelab
WORKDIR /homelab
COPY --chown=user:user ./external/unbound/entrypoint.sh ./entrypoint.sh
COPY --chown=user:user ./external/unbound/config ./config
ENV HOMELAB_CONTAINER_NAME=unbound \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER user
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "dig @$UNBOUND_HOST +short placeholder.matejhome.com || exit 1" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
