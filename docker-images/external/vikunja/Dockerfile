# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

FROM debian:12.11-slim AS prefinal
RUN mkdir -p /homelab /homelab/logs

FROM vikunja/vikunja:0.24.6
COPY ./external/vikunja/config.yml /etc/vikunja/config.yml
COPY --from=prefinal /homelab/ /homelab/
ENV HOMELAB_CONTAINER_NAME=vikunja \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "./vikunja", "user", "list" ]
