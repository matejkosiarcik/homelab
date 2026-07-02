# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Healthcheck ###

FROM golang:1.26.4-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/http-healthcheck/main.go ./.shared/healthchecks/http-healthcheck/go.mod ./.shared/healthchecks/http-healthcheck/go.sum /homelab/
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
COPY ./.shared/build-utils/create-user.sh /homelab/
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

FROM reportportal/service-jobs:5.15.1
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
USER homelab

# RP_ENVIRONMENT_VARIABLE_CLEAN_ATTACHMENT_CRON - Cron expression for the clean attachments job from database
# RP_ENVIRONMENT_VARIABLE_CLEAN_LOG_CRON - Cron expression for the clean logs job
# RP_ENVIRONMENT_VARIABLE_CLEAN_LAUNCH_CRON - Cron expression for the clean launches job
# RP_ENVIRONMENT_VARIABLE_BATCH-SIZE - Number of launches to be processed in one batch
# RP_ENVIRONMENT_VARIABLE_CLEAN_STORAGE_CRON - Cron expression for the clean storage job (binary storage)
# RP_ENVIRONMENT_VARIABLE_STORAGE_PROJECT_CRON - Cron expression for calculating average project attachments storage job
# RP_ENVIRONMENT_VARIABLE_CLEAN_EXPIREDUSER_CRON - Cron expression for the clean expired user job
# RP_ENVIRONMENT_VARIABLE_CLEAN_EXPIREDUSER_RETENTIONPERIOD - Number of days to keep expired users in the database
# RP_ENVIRONMENT_VARIABLE_NOTIFICATION_EXPIREDUSER_CRON - Cron expression for the notification expired user job
# RP_ENVIRONMENT_VARIABLE_CLEAN_EVENTS_RETENTIONPERIOD - Number of days to keep events in the database
# RP_ENVIRONMENT_VARIABLE_CLEAN_EVENTS_CRON - Cron expression for the clean events job
# RP_ENVIRONMENT_VARIABLE_CLEAN_STORAGE_CHUNKSIZE - Number of binaries to be removed from binary storage by storageProjectCron within one job execution
ENV DATASTORE_TYPE="filesystem" \
    HOMELAB_CONTAINER_NAME="reportportal-jobs" \
    HOMELAB_CONTAINER_VARIANT="default" \
    JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom -XX:+UseG1GC -XX:+UseStringDeduplication -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=60 -XX:MaxRAMPercentage=70.0 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp" \
    RP_AMQP_ANALYZER-VHOST="app-analyzer" \
    RP_AMQP_APIPORT="15672" \
    RP_AMQP_APIUSER="rabbitmq" \
    RP_AMQP_HOST="rabbitmq" \
    RP_AMQP_MAXLOGCONSUMER="1" \
    RP_AMQP_PORT="5672" \
    RP_AMQP_USER="rabbitmq" \
    RP_DB_HOST="postgres" \
    RP_DB_NAME="reportportal" \
    RP_DB_PORT="5432" \
    RP_DB_USER="postgres" \
    RP_ENVIRONMENT_VARIABLE_BATCH-SIZE="10000" \
    RP_ENVIRONMENT_VARIABLE_CLEAN_ATTACHMENT_CRON="0 0 */24 * * *" \
    RP_ENVIRONMENT_VARIABLE_CLEAN_EVENTS_CRON="0 30 05 * * *" \
    RP_ENVIRONMENT_VARIABLE_CLEAN_EVENTS_RETENTIONPERIOD="365" \
    RP_ENVIRONMENT_VARIABLE_CLEAN_EXPIREDUSER_CRON="0 0 */24 * * *" \
    RP_ENVIRONMENT_VARIABLE_CLEAN_EXPIREDUSER_RETENTIONPERIOD="365" \
    RP_ENVIRONMENT_VARIABLE_CLEAN_LAUNCH_CRON="0 0 */24 * * *" \
    RP_ENVIRONMENT_VARIABLE_CLEAN_LOG_CRON="0 0 */24 * * *" \
    RP_ENVIRONMENT_VARIABLE_CLEAN_STORAGE_CHUNKSIZE="20000" \
    RP_ENVIRONMENT_VARIABLE_CLEAN_STORAGE_CRON="0 0 */24 * * *" \
    RP_ENVIRONMENT_VARIABLE_NOTIFICATION_EXPIREDUSER_CRON="0 0 */24 * * *" \
    RP_ENVIRONMENT_VARIABLE_STORAGE_PROJECT_CRON="0 */5 * * * *" \
    RP_PROCESSING_LOG_MAXBATCHSIZE="2000" \
    RP_PROCESSING_LOG_MAXBATCHTIMEOUT="6000" \
    TZ="Europe/Bratislava"

HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:8686/health" ]
