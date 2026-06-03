# syntax=docker/dockerfile:1

### App ###

FROM freikin/dawarich:0.36.1 AS app
USER root
WORKDIR /homelab
# hadolint ignore=DL3003
RUN mkdir -p /homelab/original/var/app/db && \
    cp -R /var/app/db/. /homelab/original/var/app/db && \
    rm -rf /var/app/db && \
    cd /var/app && \
    bundle install --with development && \
    find 'vendor/bundle/ruby' -path '*.*.*/cache/*.gem' -prune -exec rm -rf {} \; && \
    rm -rf ./tmp/cache

### Healthcheck ###

FROM golang:1.26.4-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/http-healthcheck/main.go ./.shared/healthchecks/http-healthcheck/go.mod ./.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=dawarich-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=dawarich-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Users ###

FROM gcr.io/distroless/static-debian13 AS user-setup-base

FROM debian:13.5-slim AS user-setup
USER root
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab
COPY ./external/dawarich/entrypoint.sh /homelab/
COPY --from=app /homelab/original /homelab/original
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY --from=app /var/app /var/app

### Final ###

FROM freikin/dawarich:0.36.1
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
RUN rm -rf /var/app
COPY --from=prefinal --chown=homelab:homelab /var/app /var/app
ENV APPLICATION_PROTOCOL=http \
    BACKGROUND_PROCESSING_CONCURRENCY=10 \
    DATABASE_HOST=postgis \
    DATABASE_NAME=dawarich \
    DATABASE_USERNAME=postgres \
    DISABLE_TELEMETRY=true \
    HOMELAB_CONTAINER_NAME=dawarich \
    HOMELAB_CONTAINER_VARIANT=default \
    MIN_MINUTES_SPENT_IN_CITY=60 \
    PROMETHEUS_EXPORTER_ENABLED=true \
    PROMETHEUS_EXPORTER_HOST=0.0.0.0 \
    PROMETHEUS_EXPORTER_PORT=9394 \
    RAILS_ENV=development \
    REDIS_URL=redis://redis:6379 \
    SELF_HOSTED=true \
    STORE_GEODATA=true \
    TIME_ZONE=Europe/Bratislava \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=5s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:3000/api/v1/health", "--body", "\"status\"\\s*:\\s*\"ok\"" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
CMD []
