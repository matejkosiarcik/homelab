# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### App ###

FROM couchdb:3.5.1 AS entrypoint
USER root
WORKDIR /homelab
COPY ./docker-images/couchdb/entrypoint-extra.sh /homelab/
RUN head -n 1 /docker-entrypoint.sh >/homelab/entrypoint-upstream-shebang.sh && \
    tail -n +2 /docker-entrypoint.sh >/homelab/entrypoint-upstream-rest.sh && \
    cat /homelab/entrypoint-upstream-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-upstream-rest.sh >/homelab/entrypoint-final.sh && \
    chmod u=rx,go= /homelab/entrypoint-final.sh

FROM couchdb:3.5.1 AS runtime-dirs
USER root
RUN mkdir -p /homelab/original/opt/couchdb/etc/local.d && \
    cp -R /opt/couchdb/etc/local.d/. /homelab/original/opt/couchdb/etc/local.d

### Healthcheck ###

FROM golang:1.26.4-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=couchdb-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=couchdb-healthcheck-build-gobuildcache \
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
WORKDIR /homelab
COPY --from=runtime-dirs /homelab/original /homelab/original
COPY ./docker-images/couchdb/jwt.ini /homelab/original/opt/couchdb/etc/local.d/
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
WORKDIR /
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY --from=entrypoint /homelab/entrypoint-final.sh /fsroot/entrypoint/docker-entrypoint.sh

### Final ###

FROM couchdb:3.5.1
USER root
RUN rm -rf /opt/couchdb/etc/local.d
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/entrypoint/docker-entrypoint.sh /
ENV COUCHDB_USER=admin \
    HOMELAB_CONTAINER_NAME=couchdb \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:5984/_up" ]
