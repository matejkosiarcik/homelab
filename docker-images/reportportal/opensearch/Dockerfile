# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

### Healthcheck ###

FROM golang:1.27.4-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280 AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### App ###

FROM opensearchproject/opensearch:3.10.1@sha256:02358b2be62b268a404a54581184d027ac0dfa8f875be15fe4c4fa3f8884f464 AS entrypoint
USER root
COPY ./docker-images/reportportal/opensearch/entrypoint-extra.sh /homelab/
RUN head -n 1 /usr/share/opensearch/opensearch-docker-entrypoint.sh >/homelab/entrypoint-upstream-shebang.sh && \
    tail -n +2 /usr/share/opensearch/opensearch-docker-entrypoint.sh >/homelab/entrypoint-upstream-rest.sh && \
    cat /homelab/entrypoint-upstream-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-upstream-rest.sh >/homelab/entrypoint-final.sh && \
    chmod u=rx,go= /homelab/entrypoint-final.sh

FROM opensearchproject/opensearch:3.10.1@sha256:02358b2be62b268a404a54581184d027ac0dfa8f875be15fe4c4fa3f8884f464 AS runtime_dirs
USER root
RUN mkdir -p '/homelab/original/usr/share/opensearch/config' && \
    cp -R '/usr/share/opensearch/config/.' '/homelab/original/usr/share/opensearch/config'

### Users ###

FROM gcr.io/distroless/static-debian13:latest@sha256:4c2cd1dee442c9a99924a378c7c126fac8fef14771579ef567c3f2bdd7a5122a AS user_setup_base

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS user_setup
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
COPY --from=runtime_dirs /homelab/original /homelab/original

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=entrypoint /homelab/entrypoint-final.sh /fsroot/entrypoint/opensearch-docker-entrypoint.sh

### Final ###

FROM opensearchproject/opensearch:3.10.1@sha256:02358b2be62b268a404a54581184d027ac0dfa8f875be15fe4c4fa3f8884f464 AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
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
    OPENSEARCH_TMPDIR="/tmp/exec" \
    plugins.security.disabled="true" \
    PATH="/homelab/bin:${PATH}"

# Port 9200 - OpenSearch HTTP API
# Port 9600 - OpenSearch Performance Analyzer
EXPOSE 9200 9600

# TODO: Validate response body
# Original healthcheck: curl -s -f http://localhost:9200/_cluster/health | grep -q '\"status\":\"green\"\\|\"status\":\"yellow\"'
HEALTHCHECK --interval=10s --start-period=1m --timeout=2s --retries=1 CMD [ "healthcheck", "--endpoint", "{\"url\":\"http://localhost:9200/_cluster/health\"}" ]
