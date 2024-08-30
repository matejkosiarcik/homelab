# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in

FROM b4bz/homer:v24.05.1
COPY ./external/homer/assets/ /www/assets/
ENV HOMELAB_CONTAINER_NAME=homer \
    HOMELAB_CONTAINER_VARIANT=default \
    INIT_ASSETS=0 \
    PORT=80 \
    TZ=Europe/Bratislava
