FROM minio/minio:RELEASE.2025-07-23T15-54-02Z AS minio

FROM debian:13.0-slim
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
ARG UID=999
ARG GID=999
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" )
COPY --from=minio --chown=user:user /usr/bin/minio /usr/bin/minio
ENV HOMELAB_CONTAINER_NAME=minio-server \
    HOMELAB_CONTAINER_VARIANT=default \
    MINIO_ROOT_USER=admin \
    TZ=Europe/Bratislava
USER user
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:9000/minio/health/live || exit 1" ]
ENTRYPOINT [ "minio" ]
CMD [ "server", "/data", "--address", ":9000", "--console-address", ":9001" ]
USER user
