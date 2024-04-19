FROM alpine:3.19.1
RUN apk --no-cache add postgresql16-client && \
    mkdir -p /app /backup
COPY backup.sh /app/backup.sh
COPY entrypoint.sh /app/entrypoint.sh
COPY schedule.cron /app/schedule.cron
VOLUME /backup
VOLUME /log
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
