# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM debian:12.6-slim AS prefinal
WORKDIR /app
COPY ./.shared/cron/cron-wrapper.sh ./.shared/cron/entrypoint.sh ./custom/certificate-manager/crontab.cron ./custom/certificate-manager/main.sh ./

FROM debian:12.6-slim
WORKDIR /app
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends cron openssl >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /certs /log
COPY --from=prefinal /app /app
VOLUME [ "/certs" ]
ENV TZ=Europe/Bratislava
HEALTHCHECK --interval=20s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /app/.internal/status /dev/stdin >/dev/null 2>&1 || exit 1" ]
# TODO: Update to --interval=10s --start-period=15s
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
