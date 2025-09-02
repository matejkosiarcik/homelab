FROM dgtlmoon/changedetection.io:0.50.11
ARG UID=1000
ARG GID=1000
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab && \
    chown -R user:user /homelab
COPY --chown=user:user ./external/changedetection/healthcheck.py /homelab/
ENV FETCH_WORKERS=4 \
    HOMELAB_CONTAINER_NAME=changedetection \
    HOMELAB_CONTAINER_VARIANT=default \
    LOGGER_LEVEL=WARNING \
    TZ=Europe/Bratislava \
    PLAYWRIGHT_DRIVER_URL=ws://sockpuppetbrowser:3000
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "python3 /homelab/healthcheck.py || exit 1" ]
USER user
