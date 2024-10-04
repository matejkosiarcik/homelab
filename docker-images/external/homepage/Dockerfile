# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in

FROM litetex/ghcr.gethomepage.homepage:v0.9.10
COPY ./external/homepage/config/ /app/config/
COPY ./external/homepage/icons/ /app/public/icons/
ENV HOMELAB_CONTAINER_NAME=homepage \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
