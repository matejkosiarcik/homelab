# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

FROM debian:13.7-slim AS user_setup
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

### Final ###

# hadolint ignore=DL3029
FROM --platform=linux/amd64 postgis/postgis:18-3.6
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
ENV PGDATA="/var/lib/postgresql/data/database" \
    POSTGRES_DB="database" \
    POSTGRES_USER="postgres" \
    HOMELAB_CONTAINER_NAME="postgis" \
    HOMELAB_CONTAINER_VARIANT="default" \
    TZ="Europe/Bratislava"

# NOTE: The PGDATA has to be a subdirectory in "/var/lib/postgresql/data" so postgres can create it itself
# otherwise there are permissions problems in Docker Desktop

USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB} || exit 1" ]
