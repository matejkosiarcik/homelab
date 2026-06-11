# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Healthcheck ###

FROM golang:1.26.4-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/http-healthcheck/main.go ./.shared/healthchecks/http-healthcheck/go.mod ./.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=groceries-backend-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=groceries-backend-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

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
WORKDIR /homelab
COPY ./external/groceries-backend/healthcheck.js /homelab/healthcheck.js
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY ./external/groceries-backend/globalItems.json /usr/app/data/globalItems.json
COPY ./external/groceries-backend/categories.json /usr/app/data/categories.json

### Final ###

FROM ghcr.io/davideshay/groceries-server:1.1.9
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /usr/app/data/globalItems.json /usr/app/data/globalItems.json
COPY --from=prefinal --chown=homelab:homelab /usr/app/data/categories.json /usr/app/data/categories.json
ENV ACCESS_TOKEN_EXPIRES=12h \
    COUCHDB_ADMIN_USER=admin \
    COUCHDB_DATABASE=groceries \
    COUCHDB_INTERNAL_URL=http://couchdb:5984 \
    COUCHDB_URL=https://placeholder.matejhome.com/couchdb \
    COUCHDB_USER=admin \
    DISABLE_ACCOUNT_CREATION=1 \
    ENABLE_SCHEDULING=1 \
    EXPIRE_JWT_FREQUENCY_MINUTES=60 \
    GROCERY_API_PORT=3333 \
    GROCERY_API_URL=https://placeholder.matejhome.com/api \
    GROCERY_URL=https://placeholder.matejhome.com \
    HOMELAB_CONTAINER_NAME=groceries-backend \
    HOMELAB_CONTAINER_VARIANT=default \
    REFRESH_TOKEN_EXPIRES=30d \
    RESOLVE_CONFLICTS_FREQUENCY_MINUTES=5 \
    SMTP_FROM=placeholder@matejhome.com \
    SMTP_HOST=smtp4dev.matejhome.com \
    SMTP_PORT=25 \
    SMTP_USER=sender \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=5s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:3333" ]
