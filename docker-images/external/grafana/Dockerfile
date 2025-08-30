FROM grafana/grafana-oss:12.1.1
USER root
RUN apk update --no-cache && \
    apk add --no-cache shadow
ARG UID=1999
ARG GID=1999
RUN ( addgroup -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( adduser -D -u "$UID" -G user user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" )
ENV GF_PLUGINS_PREINSTALL= \
    GF_SECURITY_ADMIN_USER=admin \
    GF_SECURITY_COOKIE_SAMESITE=strict \
    GF_SECURITY_COOKIE_SECURE=true \
    GF_SECURITY_DISABLE_GRAVATAR=true \
    HOMELAB_CONTAINER_NAME=grafana \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:3000 || exit 1" ]
USER user
