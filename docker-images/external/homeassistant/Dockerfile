FROM homeassistant/home-assistant:2025.9.4
RUN apk update --no-cache && \
    apk add --no-cache shadow
ARG UID=1000
ARG GID=1000
RUN ( addgroup -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( adduser -D -u "$UID" -G user user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" )
ENV HOMELAB_CONTAINER_NAME=homeassistant \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:8123 || exit 1" ]
USER user
