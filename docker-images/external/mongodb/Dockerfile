FROM mongo:8.0.13
ARG UID=1000
ARG GID=1000
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" )
COPY --chown=user:user ./external/mongodb/healthcheck.sh /homelab/
ENV HOMELAB_CONTAINER_NAME=mongodb \
    HOMELAB_CONTAINER_VARIANT=default \
    MONGO_DBNAME=database \
    MONGO_INITDB_ROOT_USERNAME=root \
    MONGO_USER=mongo \
    PORT=27017 \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "/homelab/healthcheck.sh" ]
CMD [ "--auth", "--quiet", "--logpath", "/dev/null" ]
USER user
