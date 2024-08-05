# checkov:skip=CKV_DOCKER_3: no need for explicit user

# FROM alpine:3.20.2
# WORKDIR /app
# RUN apk update --no-cache && \
#     apk add --no-cache curl postgresql16-client && \
#     mkdir -p /backup /log

# TODO: Switch to regular stable debian when trixie is released
# Currently postgresql-client-16 is not available in bookworm
FROM debian:trixie-slim
WORKDIR /app
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends cron postgresql-client-16 >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /backup /log
COPY ./.shared/cron/cron-wrapper.sh ./.shared/cron/entrypoint.sh ./custom/postgres-backup/crontab.cron ./custom/postgres-backup/main.sh ./
ENV PGDATABASE=database \
    PGUSER=postgres \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=30s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /app/.internal/status /dev/stdin >/dev/null 2>&1 || exit 1" ]
STOPSIGNAL SIGKILL
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
