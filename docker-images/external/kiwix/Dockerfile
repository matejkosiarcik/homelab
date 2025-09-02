FROM ghcr.io/kiwix/kiwix-serve:3.7.0
RUN apk update --no-cache && \
    apk add --no-cache shadow
ARG UID=1000
ARG GID=1000
RUN ( addgroup -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( adduser -D -u "$UID" -G user user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" )
COPY --chown=user:user ./external/kiwix/entrypoint.sh /homelab/entrypoint.sh
ENV HOMELAB_CONTAINER_NAME=kiwix \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "wget -O /dev/null http://localhost:8080 || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
USER user
