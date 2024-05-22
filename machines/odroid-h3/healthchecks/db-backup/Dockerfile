# hadolint ignore=DL3002
# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM alpine:3.20.0
WORKDIR /app
RUN apk update --no-cache && \
    apk add --no-cache curl postgresql16-client && \
    mkdir -p /backup /log
COPY main.sh schedule.cron ./
HEALTHCHECK --interval=30s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /app/.internal/status /dev/stdin >/dev/null 2>&1 || exit 1" ]
# TODO: Update to --interval=10s --start-period=25s
STOPSIGNAL SIGKILL
VOLUME [ "/backup", "/log" ]
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
