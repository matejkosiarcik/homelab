# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### App ###

FROM ghcr.io/plankanban/planka:2.2.1 AS entrypoint
USER root
WORKDIR /homelab
COPY ./docker-images/planka/entrypoint-extra.sh /homelab/
RUN head -n 1 /usr/local/bin/docker-entrypoint.sh >/homelab/entrypoint-upstream-shebang.sh && \
    tail -n +2 /usr/local/bin/docker-entrypoint.sh >/homelab/entrypoint-upstream-rest.sh && \
    cat /homelab/entrypoint-upstream-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-upstream-rest.sh >/homelab/entrypoint-final.sh && \
    chmod u=rx,go= /homelab/entrypoint-final.sh

### Healthcheck ###

FROM golang:1.27.1-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Users ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

FROM debian:13.6-slim AS user_setup
USER root
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab_dir
USER root
WORKDIR /homelab
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=entrypoint /homelab/entrypoint-final.sh /fsroot/entrypoint/docker-entrypoint.sh

### Final ###

FROM ghcr.io/plankanban/planka:2.2.1
USER root
ARG HOMELAB_APP_EXTERNAL_URL
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/entrypoint/docker-entrypoint.sh /usr/local/bin/
ENV BASE_URL="${HOMELAB_APP_EXTERNAL_URL}" \
    HOMELAB_CONTAINER_NAME="planka" \
    HOMELAB_CONTAINER_VARIANT="default" \
    KNEX_REJECT_UNAUTHORIZED_SSL_CERTIFICATE="false" \
    NODE_EXTRA_CA_CERTS="/homelab/certs/postgres.crt" \
    PGSSLMODE="verify-full" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:1337" ]
