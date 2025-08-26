# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM registry:3.0.0
RUN apk add --no-cache shadow
ARG UID=999
ARG GID=999
RUN ( addgroup -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( adduser -D -u "$UID" -G user user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab && \
    chown -R user:user /homelab
USER user
COPY --chown=user:user ./external/docker-registry/config.yml /etc/distribution/config.yml
ENV HOMELAB_CONTAINER_NAME=docker-registry \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "wget -O /dev/null http://localhost || exit 1" ]
