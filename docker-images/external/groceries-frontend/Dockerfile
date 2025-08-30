FROM ghcr.io/davideshay/groceries-client:1.1.9
ARG UID=999
ARG GID=999
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab/nginx-html && \
    find /usr/share/nginx/html -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/usr/share/nginx/html/$(basename "$1")" "/homelab/nginx-html/$(basename "$1")"' - {} \; && \
    find /usr/share/nginx/html -mindepth 1 -maxdepth 1 -exec rm -rf {} \;
COPY --chown=user:user ./external/groceries-frontend/docker-entrypoint-extra.sh /homelab/
RUN head -n 1 /docker-entrypoint.sh >/homelab/docker-entrypoint-shebang.sh && \
    tail -n +2 /docker-entrypoint.sh >/homelab/docker-entrypoint-without-shebang.sh && \
    cat /homelab/docker-entrypoint-shebang.sh /homelab/docker-entrypoint-extra.sh /homelab/docker-entrypoint-without-shebang.sh >/docker-entrypoint.sh
COPY --chown=user:user ./external/groceries-frontend/nginx.conf /etc/nginx/conf.d/default.conf
ENV COUCHDB_USER=admin \
    DEFAULT_API_URL=https://placeholder.matejhome.com/api \
    HOMELAB_CONTAINER_NAME=groceries-frontend \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:8100 || exit 1" ]
USER user
