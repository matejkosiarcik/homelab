# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Users ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.5-slim AS user-setup
USER root
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
USER root
WORKDIR /homelab

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

FROM bitnamilegacy/rabbitmq:4.1.3-debian-12-r1
# FROM rabbitmq:4.3.2-management
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
RUN chown -R 'homelab:homelab' /opt/bitnami/rabbitmq
USER homelab

# RABBITMQ_DISK_FREE_ABSOLUTE_LIMIT - Blocks all procedures when free disk space is less than 50MB, see: https://www.rabbitmq.com/docs/disk-alarms
ENV HOMELAB_CONTAINER_NAME="rabbitmq" \
    HOMELAB_CONTAINER_VARIANT="default" \
    RABBITMQ_DEFAULT_USER="rabbitmq" \
    RABBITMQ_DISK_FREE_ABSOLUTE_LIMIT="100MB" \
    RABBITMQ_MANAGEMENT_ALLOW_WEB_ACCESS="true" \
    RABBITMQ_PLUGINS="rabbitmq_consistent_hash_exchange rabbitmq_management rabbitmq_auth_backend_ldap rabbitmq_shovel rabbitmq_shovel_management" \
    TZ="Europe/Bratislava"

# Port 5672 - AMQP protocol port
# Port 15672 - RabbitMQ dashboard
EXPOSE 5672 15672

HEALTHCHECK --interval=15s --start-period=60s --timeout=10s --retries=1 CMD [ "rabbitmqctl", "status" ]
