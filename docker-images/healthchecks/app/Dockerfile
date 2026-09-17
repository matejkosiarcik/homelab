# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Healthcheck ###

FROM golang:1.27.1-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Other ###

FROM debian:13.6-slim AS empty_dir
USER root
RUN mkdir /empty

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

FROM debian:13.6-slim AS user_setup
USER root
WORKDIR /homelab
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab_dir
USER root
WORKDIR /homelab
COPY --from=empty_dir /empty /homelab/healthchecks
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY ./docker-images/healthchecks/app/icons/healthchecks.png /custom-healthchecks.png

### Final ###

FROM healthchecks/healthchecks:v4.4
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /custom-healthchecks.png /opt/healthchecks/static-collected/img/
ENV DB="sqlite" \
    DB_NAME="/homelab/healthchecks/database.db" \
    DEBUG="False" \
    EMAIL_HOST="smtp4dev.matejhome.com" \
    EMAIL_PORT="25" \
    EMAIL_USE_SSL="False" \
    EMAIL_USE_TLS="False" \
    HOMELAB_CONTAINER_NAME="healthchecks" \
    HOMELAB_CONTAINER_VARIANT="default" \
    INTEGRATIONS_ALLOW_PRIVATE_IPS="True" \
    PROMETHEUS_ENABLED="True" \
    REGISTRATION_OPEN="False" \
    SHELL_ENABLED="False" \
    SITE_LOGO_URL="/static/img/custom-healthchecks.png" \
    SITE_NAME="Healthchecks" \
    TZ="Europe/Bratislava"
# TODO: Enable secure emails
# EMAIL_HOST_PASSWORD=
# EMAIL_HOST_USER=
# EMAIL_USE_SSL=False
# EMAIL_USE_TLS=True
USER homelab
# Multiple statuses are for dev and prod environments
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:8000", "--status", "200,400" ]
