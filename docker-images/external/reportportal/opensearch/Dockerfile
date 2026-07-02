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

### App ###

FROM opensearchproject/opensearch:2.19.4 AS entrypoint
USER root
COPY ./external/reportportal/opensearch/entrypoint-extra.sh /homelab/
RUN head -n 1 /usr/share/opensearch/opensearch-docker-entrypoint.sh >/homelab/entrypoint-upstream-shebang.sh && \
    tail -n +2 /usr/share/opensearch/opensearch-docker-entrypoint.sh >/homelab/entrypoint-upstream-rest.sh && \
    cat /homelab/entrypoint-upstream-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-upstream-rest.sh >/homelab/entrypoint-final.sh && \
    chmod u=rx,go= /homelab/entrypoint-final.sh

FROM opensearchproject/opensearch:2.19.4 AS runtime-dirs
USER root
RUN mkdir -p /homelab/original/usr/share/opensearch/config && \
    cp -R /usr/share/opensearch/config/. /homelab/original/usr/share/opensearch/config

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
COPY --from=runtime-dirs /homelab/original /homelab/original

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY --from=entrypoint /homelab/entrypoint-final.sh /fsroot/entrypoint/opensearch-docker-entrypoint.sh

### Final ###

FROM opensearchproject/opensearch:2.19.4
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/entrypoint/opensearch-docker-entrypoint.sh /usr/share/opensearch/
USER homelab

ENV bootstrap.memory_lock="true" \
    DISABLE_INSTALL_DEMO_CONFIG="true" \
    discovery.type="single-node" \
    HOMELAB_CONTAINER_NAME="opensearch" \
    HOMELAB_CONTAINER_VARIANT="default" \
    OPENSEARCH_JAVA_OPTS="-Xms512m -Xmx512m" \
    plugins.security.disabled="true"

# Port 9200 - OpenSearch HTTP API
# Port 9600 - OpenSearch Performance Analyzer
EXPOSE 9200 9600

# TODO: Validate response body
# Original healthcheck: curl -s -f http://localhost:9200/_cluster/health | grep -q '\"status\":\"green\"\\|\"status\":\"yellow\"'
HEALTHCHECK --interval=15s --start-period=90s --timeout=5s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:9200/_cluster/health" ]
