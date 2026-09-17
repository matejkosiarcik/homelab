# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

FROM debian:13.6-slim AS user_setup
USER root
WORKDIR /homelab
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY ./docker-images/gotify/app/config.yml /etc/gotify/config.yml

### Final ###

FROM gotify/server:2.9.1
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /etc/gotify/config.yml /etc/gotify/config.yml
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
RUN chmod go-rw /etc/gotify/config.yml
ENV HOMELAB_CONTAINER_NAME="gotify" \
    HOMELAB_CONTAINER_VARIANT="default" \
    TZ="Europe/Bratislava"
USER homelab
