# syntax = edrevo/dockerfile-plus
# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in
# checkov:skip=CKV_DOCKER_7: False positive for ":latest" tag with included build stages

### Final ####

FROM debian:12.11-slim AS prefinal
WORKDIR /homelab

FROM gotify/server:2.6.3
COPY ./external/gotify/config.yml /etc/gotify/config.yml
COPY --from=prefinal /homelab/ /homelab/
RUN chmod go-rw /etc/gotify/config.yml
ENV HOMELAB_CONTAINER_NAME=gotify \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
