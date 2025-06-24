# syntax = edrevo/dockerfile-plus
# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_8: Ignore root user

INCLUDE+ ./.shared/build-stages/supercronic/Dockerfile

FROM debian:12.11-slim AS prefinal
WORKDIR /homelab
COPY --from=supercronic /homelab/ ./
COPY ./external/renovatebot/crontab.cron ./external/renovatebot/main.sh ./

FROM renovate/renovate:41.6.3-full
# hadolint ignore=DL3002
USER root
COPY --from=prefinal /homelab/ /homelab/
COPY ./external/renovatebot/config.js /usr/src/app/config.js
ENV HOMELAB_CONTAINER_NAME=renovatebot \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="/homelab/bin:$PATH" \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=10m --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /homelab/.internal/status.txt /dev/stdin >/dev/null 2>&1 || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
