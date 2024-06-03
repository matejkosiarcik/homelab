# checkov:skip=CKV_DOCKER_8: allow root user

FROM postgres:16.3
ENV PGDATA=/var/lib/postgresql/data/pgdata \
    TZ=Europe/Bratislava \
    POSTGRES_DB=database \
    POSTGRES_USER=postgres \
    POSTGRES_PASSWORD_FILE=/.homelab/password.txt \
    PGDATABASE=database \
    PGUSER=postgres
HEALTHCHECK --interval=20s --timeout=2s --retries=1 CMD [ "sh", "-c", "pg_isready || exit 1" ]
