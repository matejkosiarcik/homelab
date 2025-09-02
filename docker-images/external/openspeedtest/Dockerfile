FROM openspeedtest/latest:v2.0.6
USER root
RUN mkdir -p /homelab/etc-nginx-conf.d && \
    find /etc/nginx/conf.d -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/etc/nginx/conf.d/$(basename "$1")" "/homelab/etc-nginx-conf.d/$(basename "$1")"' - {} \; && \
    rm -rf /etc/nginx/conf.d
COPY ./external/openspeedtest/docker-entrypoint-extra.sh /homelab/
RUN mkdir -p /homelab && \
    head -n 1 /entrypoint.sh >/homelab/docker-entrypoint-shebang.sh && \
    tail -n +2 /entrypoint.sh >/homelab/docker-entrypoint-without-shebang.sh && \
    cat /homelab/docker-entrypoint-shebang.sh /homelab/docker-entrypoint-extra.sh /homelab/docker-entrypoint-without-shebang.sh >/entrypoint.sh && \
    rm -rf /homelab/docker-entrypoint-extra.sh
RUN apk update --no-cache && \
    apk add --no-cache shadow
ARG UID=1000
ARG GID=1000
RUN ( addgroup -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( adduser -D -u "$UID" -G user user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    chmod a+x "$(which crond)" && \
    chown -R user:user /etc/nginx /homelab
ENV ENABLE_LETSENCRYPT=False \
    HOMELAB_CONTAINER_NAME=openspeedtest \
    HOMELAB_CONTAINER_VARIANT=default \
    PGID=$GID \
    PUID=$UID \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:3000 || exit 1" ]
USER user
