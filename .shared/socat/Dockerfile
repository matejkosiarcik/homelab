# checkov:skip=CKV_DOCKER_8: allow root user

# Can't upgrade to 1.8.0.0 because of https://github.com/termux/termux-packages/issues/18645
FROM alpine/socat:1.7.4.4
WORKDIR /app
COPY entrypoint.sh ./entrypoint.sh
HEALTHCHECK --interval=20s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /app/.internal/status /dev/stdin >/dev/null 2>&1 || exit 1" ]
ENV TZ=Europe/Bratislava
EXPOSE 80
EXPOSE 443
EXPOSE 53
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
