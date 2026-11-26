# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

### User setup ###

FROM gcr.io/distroless/static-debian13:latest@sha256:4c2cd1dee442c9a99924a378c7c126fac8fef14771579ef567c3f2bdd7a5122a AS user_setup_base

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS user_setup
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
FROM --platform=linux/amd64 postgis/postgis:19-3.7@sha256:fb3b0686833282d392a6af200c6c5234ed2d671ef372fa245106ec39b5c95945 AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
ENV HOMELAB_CONTAINER_NAME="postgis" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PATH="/homelab/bin:${PATH}" \
    PGDATA="/var/lib/postgresql/data/database" \
    POSTGRES_DB="database" \
    POSTGRES_PASSWORD="" \
    POSTGRES_USER="postgres" \
    TZ="Europe/Bratislava"

# NOTE: The PGDATA has to be a subdirectory in "/var/lib/postgresql/data" so postgres can create it itself
# otherwise there are permissions problems in Docker Desktop

USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=5s --retries=1 CMD [ "/bin/sh", "-c", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB} || exit 1" ]
