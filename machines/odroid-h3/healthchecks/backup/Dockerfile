FROM alpine:3.19.0
WORKDIR /app
RUN apk update --no-cache && \
    apk add --no-cache curl postgresql16-client && \
    mkdir -p /backup /log
COPY run.sh entrypoint.sh schedule.cron ./
VOLUME [ "/backup", "/log" ]
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
