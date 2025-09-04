FROM actualbudget/actual-server:25.9.0
ARG UID=1000
ARG GID=1000
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab && \
    chown -R user:user /homelab
COPY --chown=user:user ./external/actualbudget/healthcheck.js /homelab/
ENV ERR_ERL_UNEXPECTED_X_FORWARDED_FOR=false \
    HOMELAB_CONTAINER_NAME=actualbudget \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "node /homelab/healthcheck.js || exit 1" ]
USER user
