FROM amir20/dozzle:v8.14.3 AS dozzle

FROM debian:13.1-slim
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        ca-certificates >/dev/null && \
    rm -rf /var/lib/apt/lists/*
ARG UID=1000
ARG GID=1000
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab && \
    chown -R user:user /homelab
COPY --from=dozzle --chown=user:user /dozzle /dozzle
COPY --from=dozzle --chown=user:user /data /data
ENV DOZZLE_AUTH_PROVIDER=simple \
    DOZZLE_HOSTNAME=Server \
    DOZZLE_ENABLE_ACTIONS=false \
    HOMELAB_CONTAINER_NAME=dozzle \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER user
HEALTHCHECK --interval=10s --start-period=20s --timeout=2s --retries=1 CMD [ "/dozzle", "healthcheck" ]
ENTRYPOINT [ "/dozzle" ]
