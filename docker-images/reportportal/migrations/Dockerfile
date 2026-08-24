# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### App ###

FROM reportportal/migrations:5.15.4 AS entrypoint
USER nonroot
WORKDIR /homelab
COPY ./docker-images/reportportal/migrations/entrypoint-extra-end.sh ./docker-images/reportportal/migrations/entrypoint-extra-start.sh /homelab/
RUN head -n 1 /entrypoint.sh >/homelab/entrypoint-upstream-shebang.sh && \
    tail -n +2 /entrypoint.sh >/homelab/entrypoint-upstream-rest.sh && \
    cat /homelab/entrypoint-upstream-shebang.sh /homelab/entrypoint-extra-start.sh /homelab/entrypoint-upstream-rest.sh /homelab/entrypoint-extra-end.sh | sed 's~exec /wait-for-it.sh~bash /wait-for-it.sh~g' >/homelab/entrypoint-final.sh && \
    chmod u=rx,go= /homelab/entrypoint-final.sh

### Healthcheck ###

FROM golang:1.26.6-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/filecmp-healthcheck/main.go ./docker-images/.shared/healthchecks/filecmp-healthcheck/go.mod ./docker-images/.shared/healthchecks/filecmp-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=reportportal-migrations-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=reportportal-migrations-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Users ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.6-slim AS user-setup
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
COPY --from=entrypoint /homelab/entrypoint-final.sh /fsroot/entrypoint/entrypoint.sh

### Final ###

FROM reportportal/migrations:5.15.4
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/entrypoint/entrypoint.sh /
USER homelab

ENV HOMELAB_CONTAINER_NAME="reportportal-migrations" \
    HOMELAB_CONTAINER_VARIANT="default" \
    POSTGRES_DB="database" \
    POSTGRES_PORT="5432" \
    POSTGRES_SERVER="postgres" \
    POSTGRES_SSLMODE="require" \
    POSTGRES_USER="postgres" \
    TZ=Europe/"Bratislava"

HEALTHCHECK --interval=10s --start-period=60s --timeout=1s --retries=1 CMD [ "/homelab/bin/healthcheck", "--file", "/homelab/tmpfs/status.txt", "--content", "started" ]
