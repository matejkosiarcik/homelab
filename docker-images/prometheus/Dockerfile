# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Dependencies ###

FROM debian:13.6-slim AS yq
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=prometheus-dependency-yq-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=prometheus-dependency-yq-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/yq/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked,id=prometheus-dependency-yq-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet --resume-retries 1
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

FROM debian:13.6-slim AS jinja
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=prometheus-dependency-jinja-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=prometheus-dependency-jinja-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/jinja/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked,id=prometheus-dependency-jinja-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet --resume-retries 1
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

### App config ###

FROM yq AS monitoring_entries
USER root
WORKDIR /homelab
COPY ./servers/ /homelab/servers/
COPY ./docker-compose/ /homelab/docker-compose/
COPY ./docker-images/prometheus/parse-app-entry.sh /homelab/
RUN printf 'apps:\n' >'/homelab/app-entries.yml' && \
    find '/homelab/servers' -path '/homelab/servers/*/docker-apps/*' -mindepth 3 -maxdepth 3 -type d -not -name '.*' -print0 | xargs -0 -I% sh '/homelab/parse-app-entry.sh' % '/homelab/app-entries.yml' && \
    yq --in-place --yaml-output '.apps |= sort_by(.app, .short_name, .full_name)' '/homelab/app-entries.yml' && \
    yq '.' '/homelab/app-entries.yml' >'/homelab/app-entries.json'

FROM jinja AS prometheus_config
USER root
WORKDIR /homelab
COPY --from=monitoring_entries /homelab/app-entries.json /homelab/
COPY ./docker-images/prometheus/prometheus.yml.j2 /homelab/
RUN jinja2 './prometheus.yml.j2' './app-entries.json' --format json -o './prometheus.yml'

### Healthcheck ###

FROM golang:1.26.5-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=prometheus-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=prometheus-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.6-slim AS user-setup
USER root
WORKDIR /homelab
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab
COPY ./docker-images/prometheus/web.yml ./docker-images/prometheus/entrypoint.sh /homelab/
COPY --from=prometheus_config ./homelab/prometheus.yml /homelab/
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

FROM prom/prometheus:v3.8.1
USER root
ARG GID=1000
ARG UID=1000
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
ENV HOMELAB_CONTAINER_NAME=prometheus \
    HOMELAB_CONTAINER_VARIANT=default \
    PROMETHEUS__HOMELAB_VIEWER_USERNAME=homelab-viewer \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:9090", "--status", "401" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
CMD []
