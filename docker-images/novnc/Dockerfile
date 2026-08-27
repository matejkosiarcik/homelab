# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### App ###
# hadolint ignore=DL3029
FROM --platform=linux/amd64 bonigarcia/novnc:1.3.0 AS app
USER root
RUN mkdir -p /homelab/original/noVNC/app && \
    cp -R /root/noVNC/app/. /homelab/original/noVNC/app

### Healthcheck ###

FROM golang:1.27.0-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=adventurelog-frontend-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=adventurelog-frontend-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.6-slim AS user-setup
USER root
WORKDIR /homelab
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/
COPY --from=app /root/noVNC /homelab/noVNC
COPY --from=app /homelab/original /homelab/original
COPY ./docker-images/novnc/entrypoint.sh /homelab/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab/

### Final ###

# hadolint ignore=DL3029
FROM --platform=linux/amd64 bonigarcia/novnc:1.3.0
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
RUN rm -rf /root && \
    mkdir -p /root && \
    chmod 777 /root && \
    ln -s /homelab/noVNC /root/noVNC
# NOTE: Placeholders are replaced during runtime (in config or secrets)
ENV AUTOCONNECT=true \
    HOMELAB_CONTAINER_NAME=novnc \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava \
    VNC_PASSWORD="PLACEHOLDER" \
    VNC_SERVER="PLACEHOLDER"
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:6080" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
