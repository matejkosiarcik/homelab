# Can't upgrade to 1.8.0.0 because of https://github.com/termux/termux-packages/issues/18645
# FROM alpine/socat:1.7.4.4
# WORKDIR /app
# COPY entrypoint.sh main.sh ./

FROM debian:12.6-slim
WORKDIR /app
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends ncat socat >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd --system homelab && \
    useradd --gid homelab --system homelab && \
    chown -R homelab:homelab /app
COPY ./custom/socket-proxy/entrypoint.sh ./custom/socket-proxy/main.sh ./
ENV TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=20s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /app/.internal/status /dev/stdin >/dev/null 2>&1 || exit 1" ]
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
