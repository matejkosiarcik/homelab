# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Healthcheck ###

FROM golang:1.26.4-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=actualbudget-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=actualbudget-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Users ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.5-slim AS user-setup
USER root
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
USER root
WORKDIR /homelab
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

FROM reportportal/service-authorization:5.15.0
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
USER homelab

# RP_SAML_SESSION-LIVE - Session duration in seconds
# RP_SESSION_LIVE - SAML session duration in minutes
ENV DATASTORE_TYPE="filesystem" \
    HOMELAB_CONTAINER_NAME="reportportal-uat" \
    HOMELAB_CONTAINER_VARIANT="default" \
    JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom -XX:MinRAMPercentage=60.0 -XX:MaxRAMPercentage=90.0 --add-opens=java.base/java.lang=ALL-UNNAMED" \
    RP_AMQP_ANALYZER-VHOST="app-analyzer" \
    RP_AMQP_APIPORT="15672" \
    RP_AMQP_APIUSER="rabbitmq" \
    RP_AMQP_HOST="rabbitmq" \
    RP_AMQP_PORT="5672" \
    RP_AMQP_USER="rabbitmq" \
    RP_DB_HOST="postgres" \
    RP_DB_NAME="reportportal" \
    RP_DB_PORT="5432" \
    RP_DB_USER="postgres" \
    RP_SAML_SESSION-LIVE="4320" \
    RP_SESSION_LIVE="86400" \
    TZ="Europe/Bratislava"

HEALTHCHECK --interval=10s --start-period=90s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:9999/health" ]
