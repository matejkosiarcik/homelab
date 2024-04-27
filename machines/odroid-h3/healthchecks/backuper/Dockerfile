# hadolint ignore=DL3002
# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM alpine:3.19.1
WORKDIR /app
RUN apk update --no-cache && \
    apk add --no-cache curl postgresql16-client && \
    mkdir -p /backup /log
COPY main.sh schedule.cron ./
HEALTHCHECK NONE
STOPSIGNAL SIGKILL
VOLUME [ "/backup", "/log" ]
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
