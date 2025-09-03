# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in

FROM ghcr.io/open-webui/open-webui:v0.6.26
ARG UID=1000
ARG GID=1000
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    chown -R user:user /app
ENV HOMELAB_CONTAINER_NAME=openwebui \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER user
