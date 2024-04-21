FROM alpine:3.19.0
WORKDIR /app
RUN apk update --no-cache && \
    apk add --no-cache curl postgresql16-client && \
    adduser -h /home/user -s /bin/sh -D user && \
    mkdir -p /backup /log
COPY run.sh entrypoint.sh schedule.cron ./
USER user
HEALTHCHECK NONE
VOLUME [ "/backup", "/log" ]
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
