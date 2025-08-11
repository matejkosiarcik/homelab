# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM ghcr.io/davideshay/groceries-client:1.1.9
# RUN mkdir /usr/share/nginx/html-2 && \
#     find /usr/share/nginx/html >/list.txt && \
#     find /usr/share/nginx/html -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R /usr/share/nginx/html/$(basename $1) /usr/share/nginx/html-2/$(basename $1)' - {} \; && \
#     mkdir /homelab && \
#     printf '%s\n%s\n%s\n' "find /usr/share/nginx/html-2 -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R /usr/share/nginx/html-2/\$(basename \$1) /usr/share/nginx/html/\$(basename \$1)' - {} \;" 'true' 'ls -lah /usr/share/nginx/html' >/homelab/docker-entrypoint-extra.sh && \
#     head -n 1 /docker-entrypoint.sh >/homelab/docker-entrypoint-shebang.sh && \
#     tail -n +2 /docker-entrypoint.sh >/homelab/docker-entrypoint-without-shebang.sh && \
#     cat /homelab/docker-entrypoint-shebang.sh /homelab/docker-entrypoint-extra.sh /homelab/docker-entrypoint-without-shebang.sh >/docker-entrypoint.sh && \
#     find /usr/share/nginx/html -mindepth 1 -maxdepth 1 -exec rm -rf {} \; && \
#     rm -rf /homelab
COPY ./external/groceries-frontend/nginx.conf /etc/nginx/conf.d/default.conf
ENV COUCHDB_USER=admin \
    DEFAULT_API_URL=https://placeholder.matejhome.com/api \
    HOMELAB_CONTAINER_NAME=groceries-frontend \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:8100 || exit 1" ]
