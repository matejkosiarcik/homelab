# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### App ###

FROM freikin/dawarich:1.15.2 AS app
USER root
WORKDIR /homelab
# hadolint ignore=DL3003
RUN mkdir -p '/homelab/original/var/app/db' && \
    cp -R '/var/app/db/.' '/homelab/original/var/app/db' && \
    rm -rf '/var/app/db' && \
    cd /var/app && \
    (test -d '/var/app/vendor/bundle/ruby/3.4.0' || (printf 'Ruby directory not found.\n' >&2; exit 1)) && \
    export PATH="/var/app/vendor/bundle/ruby/3.4.0/bin:${PATH}" && \
    export BUNDLE_PATH="/var/app/vendor/bundle/ruby/3.4.0/gems" && \
    bundle config set --local without 'test' && \
    bundle config set --local with 'development' && \
    bundle add 'prometheus_exporter' --skip-install && \
    bundle install && \
    bundle exec 'foreman' --version && \
    bundle exec 'prometheus_exporter' --help >/dev/null && \
    find './vendor/bundle/ruby' -path '*.*.*/cache/*.gem' -prune -exec rm -rf {} \; && \
    rm -rf './tmp/cache'

### Healthcheck ###

FROM golang:1.27.1-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Users ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

FROM debian:13.7-slim AS user_setup
USER root
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab
COPY ./docker-images/dawarich/entrypoint.sh /homelab/
COPY --from=app /homelab/original /homelab/original
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=app /var/app /var/app

### Final ###

FROM freikin/dawarich:1.15.2
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
RUN rm -rf /var/app
COPY --from=prefinal --chown=homelab:homelab /var/app /var/app
ENV APPLICATION_PROTOCOL="http" \
    BACKGROUND_PROCESSING_CONCURRENCY="10" \
    BUNDLE_PATH="/var/app/vendor/bundle/ruby/3.4.0/gems" \
    DATABASE_HOST="postgis" \
    DATABASE_NAME="database" \
    DATABASE_USERNAME="postgres" \
    DISABLE_TELEMETRY="true" \
    HOMELAB_CONTAINER_NAME="dawarich" \
    HOMELAB_CONTAINER_VARIANT="default" \
    MIN_MINUTES_SPENT_IN_CITY="60" \
    PATH="/var/app/vendor/bundle/ruby/3.4.0/bin:${PATH}" \
    PROMETHEUS_EXPORTER_ENABLED="true" \
    PROMETHEUS_EXPORTER_HOST="0.0.0.0" \
    PROMETHEUS_EXPORTER_PORT="9394" \
    RAILS_ENV="development" \
    REDIS_URL="redis://redis:6379" \
    SELF_HOSTED="true" \
    STORE_GEODATA="true" \
    TIME_ZONE="Europe/Bratislava" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=5s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:3000/api/v1/health", "--body", "\"status\"\\s*:\\s*\"ok\"" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
CMD []
