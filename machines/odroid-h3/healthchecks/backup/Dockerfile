FROM alpine:3.19.1
WORKDIR /app
RUN apk update --no-cache && \
    apk add --no-cache curl postgresql16-client sudo && \
    adduser -h /home/user -s /bin/sh -D user root && \
    mkdir -p /backup /log && \
    printf '\nuser ALL=(ALL) NOPASSWD: ALL\n' >>/etc/sudoers
COPY run.sh entrypoint.sh schedule.cron ./
USER user
HEALTHCHECK NONE
VOLUME [ "/backup", "/log" ]
ENTRYPOINT [ "sudo", "-E", "sh", "/app/entrypoint.sh" ]
