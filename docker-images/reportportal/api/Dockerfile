# syntax=docker/dockerfile:1

### Healthcheck ###

FROM golang:1.27.4-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Users ###

FROM gcr.io/distroless/static-debian13:latest@sha256:1a64f46364620465ef9e9a8f5413757dfdf22695e050bbfd7303eeaf17a59383 AS user_setup_base

FROM debian:13.7-slim AS user_setup
USER root
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh '/homelab/create-user.sh' && \
    pwconv && \
    passwd --lock homelab

### Prefinal ###

FROM scratch AS homelab_dir
USER root
WORKDIR /homelab
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab

### Final ###

FROM reportportal/service-api:5.15.6 AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
USER homelab

ENV AUDIT_LOGGER="OFF" \
    COM_TA_REPORTPORTAL_JOB_CLEAN_OUTDATED_PLUGINS_CRON="PT10S" \
    COM_TA_REPORTPORTAL_JOB_INTERRUPT_BROKEN_LAUNCHES_CRON="PT1H" \
    COM_TA_REPORTPORTAL_JOB_LOAD_PLUGINS_CRON="PT10S" \
    DATASTORE_TYPE="filesystem" \
    HOMELAB_CONTAINER_NAME="reportportal-api" \
    HOMELAB_CONTAINER_VARIANT="default" \
    JAVA_OPTS="-Xmx1g -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp -Dcom.sun.management.jmxremote.rmi.port=12349 -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.port=9010 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=0.0.0.0" \
    LOGGING_LEVEL_ORG_HIBERNATE_SQL="info" \
    MANAGEMENT_HEALTH_ELASTICSEARCH_ENABLED="false" \
    REPORTING_CONSUMER_PREFETCHCOUNT="10" \
    REPORTING_PARKINGLOT_TTL_DAYS="7" \
    REPORTING_QUEUES_COUNT="10" \
    RP_AMQP_ANALYZER-VHOST="app-analyzer" \
    RP_AMQP_APIPASS="" \
    RP_AMQP_APIPORT="15672" \
    RP_AMQP_APIUSER="rabbitmq" \
    RP_AMQP_HOST="rabbitmq" \
    RP_AMQP_PASS="" \
    RP_AMQP_PORT="5672" \
    RP_AMQP_USER="rabbitmq" \
    RP_DB_HOST="postgres" \
    RP_DB_NAME="database" \
    RP_DB_PASS="" \
    RP_DB_PORT="5432" \
    RP_DB_USER="postgres" \
    RP_ENVIRONMENT_VARIABLE_ALLOW_DELETE_ACCOUNT="false" \
    RP_ENVIRONMENT_VARIABLE_PATTERN-ANALYSIS_BATCH-SIZE="100" \
    RP_ENVIRONMENT_VARIABLE_PATTERN-ANALYSIS_CONSUMERS-COUNT="1" \
    RP_ENVIRONMENT_VARIABLE_PATTERN-ANALYSIS_PREFETCH-COUNT="1" \
    RP_JOBS_BASEURL="http://app-jobs:8686" \
    RP_REQUESTLOGGING="false" \
    TZ="Europe/Bratislava"

HEALTHCHECK --interval=10s --start-period=1m --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:8585/health" ]
