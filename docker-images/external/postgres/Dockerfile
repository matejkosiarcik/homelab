# syntax=docker/dockerfile:1

### Other ###

FROM debian:13.2-slim AS openssl-certificates
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=postgres-openssl-certificates-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=postgres-openssl-certificates-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        openssl && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p /homelab/certs && \
    openssl req -new -x509 -days 3650 -nodes -text -out '/homelab/certs/server.crt' -keyout '/homelab/certs/server.key' -subj '/CN=postgres' && \
    chmod 600 '/homelab/certs/server.key' && \
    chmod 644 '/homelab/certs/server.crt'

### User setup ###

FROM gcr.io/distroless/static-debian13 AS user-setup-base

FROM debian:13.2-slim AS user-setup
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
COPY ./external/postgres/postgres.conf /homelab/postgresql.conf
COPY ./external/postgres/pg_hba.conf /homelab/pg_hba.conf
COPY --from=openssl-certificates /homelab/certs /homelab/certs

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

# hadolint ignore=DL3029
FROM postgres:18.1
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=postgres-final-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=postgres-final-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        openssl && \
    rm -rf /var/lib/apt/lists/*
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
ENV PGDATA=/var/lib/postgresql/data \
    POSTGRES_DB=database \
    POSTGRES_USER=postgres \
    HOMELAB_CONTAINER_NAME=postgres \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB || exit 1" ]
CMD [ "postgres", "-c", "config_file=/homelab/postgresql.conf", "-c", "hba_file=/homelab/pg_hba.conf" ]
