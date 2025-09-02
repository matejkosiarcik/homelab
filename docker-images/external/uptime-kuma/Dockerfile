# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in

FROM louislam/uptime-kuma:2.0.0-beta.3
ARG UID=1000
ARG GID=1000
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" )
ENV HOMELAB_CONTAINER_NAME=uptime-kuma \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER user
