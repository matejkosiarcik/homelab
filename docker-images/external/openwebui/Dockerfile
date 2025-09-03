# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in

FROM ghcr.io/open-webui/open-webui:v0.6.26
RUN mkdir -p /homelab/app-static && \
    find /app/backend/open_webui/static -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/app/backend/open_webui/static/$(basename "$1")" "/homelab/app-static/$(basename "$1")"' - {} \; && \
    rm -rf /app/backend/open_webui/static
COPY ./external/openwebui/entrypoint-extra.sh /homelab/
RUN mkdir -p /homelab && \
    head -n 1 /app/backend/start.sh >/homelab/entrypoint-shebang.sh && \
    tail -n +2 /app/backend/start.sh >/homelab/entrypoint-without-shebang.sh && \
    cat /homelab/entrypoint-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-without-shebang.sh >/app/backend/start.sh && \
    rm -rf /app/config /homelab/entrypoint-extra.sh
ARG UID=1000
ARG GID=1000
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    chown -R user:user /app /homelab
ENV HOMELAB_CONTAINER_NAME=openwebui \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=300s --timeout=5s --retries=1 CMD [ "sh", "-c", "curl --silent --fail http://localhost:8080/health | jq -ne 'input.status == true' || exit 1" ]
USER user
