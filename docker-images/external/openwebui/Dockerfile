# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Healthcheck ###

FROM golang:1.26.4-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/http-healthcheck/main.go ./.shared/healthchecks/http-healthcheck/go.mod ./.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=openwebui-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=openwebui-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Other ###

FROM openwebui/open-webui:0.9.6 AS entrypoint
USER root
COPY ./external/openwebui/entrypoint-extra.sh /homelab/
RUN head -n 1 /app/backend/start.sh >/homelab/entrypoint-upstream-shebang.sh && \
    tail -n +2 /app/backend/start.sh >/homelab/entrypoint-upstream-rest.sh && \
    cat /homelab/entrypoint-upstream-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-upstream-rest.sh >/homelab/entrypoint-final.sh && \
    chmod u=rx,go= /homelab/entrypoint-final.sh

FROM openwebui/open-webui:0.9.6 AS runtime-dirs
USER root
WORKDIR /homelab
RUN mkdir -p /homelab/original/app/backend/open_webui/static && \
    cp -R /app/backend/open_webui/static/. /homelab/original/app/backend/open_webui/static

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.5-slim AS user-setup
USER root
WORKDIR /homelab
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab
COPY --from=runtime-dirs /homelab/original /homelab/original
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY --from=entrypoint /homelab/entrypoint-final.sh /fsroot/entrypoint/start.sh

### Final ###

FROM openwebui/open-webui:0.9.6
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/entrypoint/start.sh /app/backend/
RUN chown -R homelab:homelab /app && \
    rm -rf /app/backend/open_webui/static /app/config
ENV HOMELAB_CONTAINER_NAME=openwebui \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=300s --timeout=5s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:8080/health" ]
# TODO: Add validation for response 'input.status = "true"'
