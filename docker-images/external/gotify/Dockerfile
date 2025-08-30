# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in

FROM gotify/server:2.6.3
ARG UID=1999
ARG GID=1999
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" )
COPY --chown=user:user ./external/gotify/config.yml /etc/gotify/config.yml
RUN chmod go-rw /etc/gotify/config.yml
ENV HOMELAB_CONTAINER_NAME=gotify \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER user
