# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### App ###

FROM twinproduction/gatus:v5.37.0 AS gatus_app
USER root

FROM debian:13.7-slim AS gatus_setcap
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_gatus_setcap_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_gatus_setcap_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        libcap2-bin >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gatus_app /gatus /gatus
RUN setcap 'cap_net_raw+ep' /gatus

### Dependencies ###

FROM debian:13.7-slim AS yq
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_yq_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_yq_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/yq/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION="ignore"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"

FROM debian:13.7-slim AS jinja
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_jinja_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_jinja_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/jinja/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION="ignore"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"

### App config ###

FROM yq AS monitoring_entries
USER root
WORKDIR /homelab
COPY ./servers/ /homelab/servers/
COPY ./docker-compose/ /homelab/docker-compose/
COPY ./docker-images/.shared/build-utils/parse-app-entry-utils.sh ./docker-images/gatus/extra-entries.yml ./docker-images/gatus/parse-app-entry.sh /homelab/
RUN printf 'apps:\n' >'/homelab/app-entries.yml' && \
    find '/homelab/servers' -path '/homelab/servers/*/docker-apps/*' -mindepth 3 -maxdepth 3 -type d -not -name '.*' -print0 | xargs -0 -I% sh '/homelab/parse-app-entry.sh' % '/homelab/app-entries.yml' && \
    yq --in-place --yaml-output '.apps |= sort_by(.app, .short_name, .full_name, .domain)' '/homelab/app-entries.yml' && \
    cat '/homelab/extra-entries.yml' '/homelab/app-entries.yml' >'/homelab/all-entries.yml' && \
    yq '.' '/homelab/all-entries.yml' >'/homelab/data.json'

FROM jinja AS config_2
USER root
WORKDIR /homelab
COPY --from=monitoring_entries /homelab/data.json /homelab/
COPY ./docker-images/gatus/config.yml.j2 /homelab/
RUN jinja2 './config.yml.j2' './data.json' --format json -o './config.yml'

### Healthcheck ###

FROM golang:1.27.1-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Other ###

FROM debian:13.7-slim AS package_ca_certificates
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_package_ca_certificates_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_package_ca_certificates_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates >/dev/null && \
    rm -rf /var/lib/apt/lists/*

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

FROM debian:13.7-slim AS user_setup
USER root
WORKDIR /homelab
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab
COPY --from=config_2 /homelab/config.yml /homelab/
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/
COPY --from=gatus_setcap /gatus /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=package_ca_certificates /etc/ssl/certs/ca-certificates.crt /fsroot/certs/

### Final ###

FROM scratch
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/certs /etc/ssl/certs
WORKDIR /homelab
ENV GATUS_CONFIG_PATH="/homelab/config.yml" \
    GATUS_DELAY_START_SECONDS="0" \
    GATUS_LOG_LEVEL="INFO" \
    HOMELAB_CONTAINER_NAME="gatus" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PORT="8080" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:8080" ]
ENTRYPOINT [ "/homelab/bin/gatus" ]
