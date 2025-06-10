# syntax = edrevo/dockerfile-plus
# checkov:skip=CKV_DOCKER_3: No need for explicit user

INCLUDE+ ./.shared/build-stages/supercronic/Dockerfile

FROM debian:12.11-slim AS prefinal
WORKDIR /homelab
COPY --from=supercronic /homelab/ ./
COPY ./custom/certbot/crontab.cron ./custom/certbot/main.sh ./custom/certbot/certbot-hook-after.sh ./custom/certbot/certbot-hook-before.sh ./

FROM python:3.13.4-slim
WORKDIR /homelab
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        ca-certificates certbot curl jq xz-utils >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=prefinal /homelab/ ./
ENV HOMELAB_CONTAINER_NAME=certbot \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="/homelab/bin:$PATH" \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /homelab/.internal/status.txt /dev/stdin >/dev/null 2>&1 || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
