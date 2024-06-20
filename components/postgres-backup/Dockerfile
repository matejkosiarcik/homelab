# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM alpine:3.20.1
WORKDIR /app
RUN apk update --no-cache && \
    apk add --no-cache curl postgresql16-client && \
    mkdir -p /backup /log
COPY entrypoint.sh run.sh schedule.cron ./
ENV PGDATABASE=database \
    PGUSER=postgres \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=30s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /app/.internal/status /dev/stdin >/dev/null 2>&1 || exit 1" ]
VOLUME [ "/backup", "/log" ]
STOPSIGNAL SIGKILL
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
