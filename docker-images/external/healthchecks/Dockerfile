# syntax=docker/dockerfile:1

### Healthcheck ###

FROM golang:1.26.4-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/http-healthcheck/main.go ./.shared/healthchecks/http-healthcheck/go.mod ./.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=healthchecks-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=healthchecks-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Other ###

FROM debian:13.5-slim AS empty-dir
USER root
RUN mkdir /empty

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
USER root
WORKDIR /homelab
COPY --from=empty-dir /empty /homelab/healthchecks
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY ./external/healthchecks/icons/healthchecks.png /custom-healthchecks.png

### Final ###

FROM healthchecks/healthchecks:v3.13
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /custom-healthchecks.png /opt/healthchecks/static-collected/img/
ENV DB=sqlite \
    DB_NAME=/homelab/healthchecks/database.db \
    DEBUG=False \
    EMAIL_HOST=smtp4dev.matejhome.com \
    EMAIL_PORT=25 \
    EMAIL_USE_SSL=False \
    EMAIL_USE_TLS=False \
    HOMELAB_CONTAINER_NAME=healthchecks \
    HOMELAB_CONTAINER_VARIANT=default \
    INTEGRATIONS_ALLOW_PRIVATE_IPS=True \
    PROMETHEUS_ENABLED=True \
    REGISTRATION_OPEN=False \
    SHELL_ENABLED=False \
    SITE_LOGO_URL=/static/img/custom-healthchecks.png \
    TZ=Europe/Bratislava
# TODO: Enable secure emails
# EMAIL_HOST_PASSWORD=
# EMAIL_HOST_USER=
# EMAIL_USE_SSL=False
# EMAIL_USE_TLS=True
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:8000/api/v3/status/" ]
