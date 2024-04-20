FROM alpine:3.19.0
RUN apk --no-cache add postgresql16-client && \
    mkdir -p /app /backup /log
COPY backup.sh entrypoint.sh schedule.cron /app/
VOLUME /backup /log
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
