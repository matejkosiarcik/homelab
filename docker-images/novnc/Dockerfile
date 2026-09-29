# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### App ###

# hadolint ignore=DL3029
FROM --platform=linux/amd64 bonigarcia/novnc:1.3.0 AS app_original
USER root

FROM debian:13.7-slim AS app_modified
USER root
WORKDIR /homelab
COPY --from=app_original /root/noVNC /root/noVNC
RUN mkdir -p '/homelab/original/noVNC/app' && \
    cp -R '/root/noVNC/app/.' '/homelab/original/noVNC/app'

FROM debian:13.7-slim AS rm_script
USER root
WORKDIR /homelab
RUN printf '#!/bin/sh\nset -euf\nrm -rf /root\nrm -f "${0}"' >/homelab/rm.sh && \
    chmod a+x '/homelab/rm.sh'

### Healthcheck ###

FROM golang:1.27.1-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

FROM debian:13.7-slim AS user_setup
USER root
WORKDIR /homelab
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh '/homelab/create-user.sh' && \
    pwconv && \
    passwd --lock homelab

### Prefinal ###

FROM debian:13.7-slim AS homelab_dir
WORKDIR /homelab
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/
COPY --from=app_original /root/noVNC /homelab/noVNC
COPY --from=app_modified /homelab/original /homelab/original
COPY ./docker-images/novnc/entrypoint.sh /homelab/
COPY --from=rm_script /homelab/rm.sh /homelab/

FROM debian:13.7-slim AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab/
RUN mkdir -p '/root' && \
    ln -s '/homelab/noVNC' '/root/noVNC' && \
    ln -s '/homelab/noVNC' '/home/homelab/noVNC'

### Final ###

# hadolint ignore=DL3029
FROM --platform=linux/amd64 bonigarcia/novnc:1.3.0 AS final
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
# NOTE: The following script must be a script file because otherwise it errors out on the server
RUN /homelab/rm.sh
COPY --from=prefinal --chown=homelab:homelab /root /root
# NOTE: Placeholders are replaced during runtime (in config or secrets)
ENV AUTOCONNECT="true" \
    HOMELAB_CONTAINER_NAME="novnc" \
    HOMELAB_CONTAINER_VARIANT="default" \
    TZ="Europe/Bratislava" \
    VNC_PASSWORD="PLACEHOLDER" \
    VNC_SERVER="PLACEHOLDER"
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:6080" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
