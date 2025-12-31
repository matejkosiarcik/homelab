# hadolint ignore=DL3029
FROM postgres:18.1
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends --no-install-suggests \
        openssl && \
    rm -rf /var/lib/apt/lists/*
ARG GID=1000
ARG UID=1000
RUN if [ "$(getent group "$GID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
        groupadd --gid "$GID" homelab && \
    true; else \
        oldgroupname="$(getent group "$GID" | cut -d: -f1)" && \
        groupmod --new-name homelab "$oldgroupname" && \
    true; fi && \
    nologinshell='' && \
    if [ -e /sbin/nologin ]; then \
        nologinshell='/sbin/nologin' && \
    true; elif [ -e /usr/sbin/nologin ]; then \
        nologinshell='/usr/sbin/nologin' && \
    true; else \
        nologinshell='/bin/false' && \
    true; fi && \
    if [ "$(getent passwd "$UID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
        useradd --no-log-init --home /home/homelab --uid "$UID" --gid "$GID" --shell "$nologinshell" homelab && \
    true; else \
        oldusername="$(getent passwd "$UID" | cut -d: -f1)" && \
        usermod --move-home --home /home/homelab --uid "$UID" --gid "$GID" --shell "$nologinshell" --login homelab "$oldusername" && \
    true; fi && \
    mkdir -p /home/homelab /homelab /homelab/certs && \
    openssl req -new -x509 -days 3650 -nodes -text -out '/homelab/certs/server.crt' -keyout '/homelab/certs/server.key' -subj '/CN=postgres' && \
    chmod 600 '/homelab/certs/server.key' && \
    chmod 644 '/homelab/certs/server.crt' && \
    chown -R homelab:homelab /home/homelab /homelab
COPY --chown=homelab:homelab ./external/postgres/postgres.conf /homelab/postgresql.conf
COPY --chown=homelab:homelab ./external/postgres/pg_hba.conf /homelab/pg_hba.conf
ENV PGDATA=/var/lib/postgresql/data \
    POSTGRES_DB=database \
    POSTGRES_USER=postgres \
    HOMELAB_CONTAINER_NAME=postgres \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB || exit 1" ]
USER homelab
CMD [ "postgres", "-c", "config_file=/homelab/postgresql.conf", "-c", "hba_file=/homelab/pg_hba.conf" ]
