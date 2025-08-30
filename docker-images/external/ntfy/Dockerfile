# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM binwiederhier/ntfy:v2.14.0
RUN apk update --no-cache && \
    apk add --no-cache shadow
ARG UID=1999
ARG GID=1999
RUN ( addgroup -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( adduser -D -u "$UID" -G user user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab && \
    chown -R user:user /homelab
COPY --chown=user:user ./external/ntfy/setup.sh /homelab/
COPY --chown=user:user ./external/ntfy/config/server.yml /etc/ntfy/server.yml
ENV HOMELAB_CONTAINER_NAME=ntfy \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=5s --retries=1 CMD [ "sh", "-c", "wget -q --tries=1 http://localhost/v1/health -O - | grep -Eo '\"healthy\"\\s*:\\s*true' || exit 1" ]
ENTRYPOINT [ "ntfy" ]
CMD [ "serve" ]
USER user
