# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM docker:28.3.3
RUN apk update --no-cache && \
    apk add --no-cache shadow
ARG UID=1000
ARG GID=1000
RUN ( addgroup -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( adduser -D -u "$UID" -G user user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab && \
    chown -R user:user /homelab
COPY --chown=user:user ./custom/docker-setup/entrypoint.sh /homelab/
ENV HOMELAB_CONTAINER_NAME=docker-setup \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=90s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /homelab/.status/status.txt /dev/stdin >/dev/null 2>&1 || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
USER user
