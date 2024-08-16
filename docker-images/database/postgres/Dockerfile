# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM postgres:16.4
ENV PGDATA=/var/lib/postgresql/data/pgdata \
    POSTGRES_DB=database \
    POSTGRES_USER=postgres \
    POSTGRES_PASSWORD_FILE=/.homelab/password.txt \
    PGDATABASE=database \
    PGUSER=postgres \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=20s --timeout=2s --retries=1 CMD [ "sh", "-c", "pg_isready || exit 1" ]
