# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in

### User setup ###

FROM gcr.io/distroless/static-debian13 AS user-setup-base

FROM debian:13.5-slim AS user-setup
USER root
WORKDIR /homelab
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

FROM vaultwarden/server:1.34.3
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
ENV EXTENDED_LOGGING=true \
    HOMELAB_CONTAINER_NAME=vaultwarden \
    HOMELAB_CONTAINER_VARIANT=default \
    LOG_FILE=/homelab/logs/vaultwarden.log \
    LOG_LEVEL=error \
    LOG_LEVEL=warn \
    PASSWORD_ITERATIONS=500000 \
    SENDS_ALLOWED=true \
    SIGNUPS_ALLOWED=false \
    SIGNUPS_VERIFY=true \
    SMTP_FROM_NAME=Vaultwarden \
    SMTP_HOST=smtp4dev.matejhome.com \
    SMTP_PORT=25 \
    SMTP_SECURITY=off \
    SMTP_TIMEOUT=10 \
    TZ=Europe/Bratislava \
    WEBSOCKET_ENABLED=true
USER homelab

# TODO: Set SMTP authentication: SMTP_SECURITY, SMTP_USERNAME, SMTP_PASSWORD
