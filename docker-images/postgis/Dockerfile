# syntax=docker/dockerfile:1

### User setup ###

FROM gcr.io/distroless/static-debian13:latest@sha256:1a64f46364620465ef9e9a8f5413757dfdf22695e050bbfd7303eeaf17a59383 AS user_setup_base

FROM debian:13.7-slim AS user_setup
USER root
WORKDIR /homelab
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh '/homelab/create-user.sh' && \
    pwconv && \
    passwd --lock homelab

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab

### Final ###

# hadolint ignore=DL3029
FROM --platform=linux/amd64 postgis/postgis:18-3.6 AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
ENV HOMELAB_CONTAINER_NAME="postgis" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PGDATA="/var/lib/postgresql/data/database" \
    POSTGRES_DB="database" \
    POSTGRES_PASSWORD="" \
    POSTGRES_USER="postgres" \
    TZ="Europe/Bratislava"

# NOTE: The PGDATA has to be a subdirectory in "/var/lib/postgresql/data" so postgres can create it itself
# otherwise there are permissions problems in Docker Desktop

USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB} || exit 1" ]
