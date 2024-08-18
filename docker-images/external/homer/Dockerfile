# checkov:skip=CKV_DOCKER_3: no need for explicit user
# checkov:skip=CKV_DOCKER_2: healthcheck builtin

FROM b4bz/homer:v24.05.1
COPY ./external/homer/assets/ /www/assets/
ENV HOMELAB_CONTAINER_TYPE=homer \
    INIT_ASSETS=0 \
    PORT=80 \
    TZ=Europe/Bratislava
