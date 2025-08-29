FROM homeassistant/home-assistant:2025.8.3
RUN apk update --no-cache && \
    apk add --no-cache shadow
ARG UID=999
ARG GID=999
RUN ( addgroup -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( adduser -D -u "$UID" -G user user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" )
ENV HOMELAB_CONTAINER_NAME=home-assistant \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:8123 || exit 1" ]
USER user
