# syntax = edrevo/dockerfile-plus
# checkov:skip=CKV_DOCKER_3: No need for explicit user

INCLUDE+ ./.shared/build-stages/supercronic/Dockerfile

FROM debian:12.11-slim AS prefinal
WORKDIR /homelab
COPY --from=supercronic /homelab/ ./
COPY ./custom/docker-build/crontab.cron ./custom/docker-build/main.sh ./

FROM docker:28.2.2
WORKDIR /homelab
COPY --from=prefinal /homelab/ ./
ENV HOMELAB_CONTAINER_NAME=docker-build \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="/homelab/bin:$PATH" \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=90s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /homelab/.internal/status.txt /dev/stdin >/dev/null 2>&1 || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
