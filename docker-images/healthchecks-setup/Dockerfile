# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Dependencies ###

FROM debian:13.6-slim AS yq
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=healthchecks-dependency-yq-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=healthchecks-dependency-yq-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/yq/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked,id=healthchecks-dependency-yq-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet --resume-retries 1
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

FROM debian:13.6-slim AS jinja
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=healthchecks-dependency-jinja-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=healthchecks-dependency-jinja-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/jinja/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked,id=healthchecks-dependency-jinja-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet --resume-retries 1
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

### Build config ###

FROM debian:13.6-slim AS npmconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=data-optimizer-npmconfig-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=data-optimizer-npmconfig-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/anticache.txt /homelab/
RUN printf '' >/root/.npmrc && \
    { curl --fail --silent https://npm-cache.matejhome.com || exit 0; } && \
    npm config set proxy https://npm-cache.matejhome.com && \
    npm config set https-proxy https://npm-cache.matejhome.com

### App config ###

FROM yq AS config_1
USER root
WORKDIR /homelab
COPY ./servers/ /homelab/servers/
COPY ./docker-compose/ /homelab/docker-compose/
COPY ./docker-images/.shared/build-utils/parse-app-entry-utils.sh ./docker-images/healthchecks-setup/parse-app-entry.sh /homelab/
RUN printf 'apps:\n' >'/homelab/app-data.yml' && \
    find '/homelab/servers' -path '/homelab/servers/*/docker-apps/*' -mindepth 3 -maxdepth 3 -type d -not -name '.*' -print0 | xargs -0 -I% sh '/homelab/parse-app-entry.sh' % '/homelab/app-data.yml' && \
    yq --in-place --yaml-output '.apps |= sort_by(.app, .short_name, .full_name, .domain)' '/homelab/app-data.yml' && \
    yq '.' '/homelab/app-data.yml' >'/homelab/app-data.json'

FROM jinja AS config_2
USER root
WORKDIR /homelab
COPY --from=config_1 /homelab/app-data.json /homelab/
COPY ./docker-images/healthchecks-setup/healthchecks.yml.j2 /homelab/
RUN jinja2 healthchecks.yml.j2 app-data.json --format json -o healthchecks.yml

FROM yq AS config_3
USER root
WORKDIR /homelab
COPY --from=config_2 /homelab/healthchecks.yml /homelab/
RUN yq '.' '/homelab/healthchecks.yml' >'/homelab/healthchecks.json'

### App ###

FROM node:26.7.0-slim AS app_build
USER root
WORKDIR /homelab
COPY --from=npmconfig /root/.npmrc /root/.npmrc
COPY ./docker-images/healthchecks-setup/package-lock.json ./docker-images/healthchecks-setup/package.json /homelab/
RUN --mount=type=cache,target=/root/.npm,sharing=locked,id=healthchecks-setup-nodejs-build-npmcache \
    NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error --prefer-offline
COPY ./docker-images/healthchecks-setup/tsconfig.json /homelab/
COPY ./docker-images/healthchecks-setup/src/ /homelab/src/
RUN npm run build && \
    npm prune --production

### Healthcheck ###

FROM golang:1.26.6-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/filecmp-healthcheck/main.go ./docker-images/.shared/healthchecks/filecmp-healthcheck/go.mod ./docker-images/.shared/healthchecks/filecmp-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=script-setup-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=script-setup-healthcheck-build-gobuildcache \
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
COPY --from=config_3 /homelab/healthchecks.json /homelab/
COPY --from=app_build /homelab/package.json /homelab/
COPY --from=app_build /homelab/dist/ /homelab/dist/
COPY --from=app_build /homelab/node_modules/ /homelab/node_modules/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/nodejs26-debian13:latest
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME=script-setup \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=90s --timeout=1s --retries=1 CMD [ "/homelab/bin/healthcheck", "--file", "/homelab/tmpfs/status.txt", "--content", "started" ]
ENTRYPOINT [ "/nodejs/bin/node", "/homelab/dist/main.js" ]
