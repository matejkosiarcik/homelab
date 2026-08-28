# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Dependencies ###

FROM debian:13.6-slim AS yq
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=gotify-dependency-yq-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=gotify-dependency-yq-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/yq/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked,id=gotify-dependency-yq-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet --resume-retries 1
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

### Build config ###

FROM node:26.8.1-slim AS npmconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=gotify-app-setup-npmconfig-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=gotify-app-setup-npmconfig-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/anticache.txt /homelab/
RUN touch '/root/.npmrc'
# TODO: Re-enable cache below:
# RUN touch '/root/.npmrc' && \
#     { curl --fail --silent https://npm-cache.matejhome.com || exit 0; } && \
#     npm config set proxy https://npm-cache.matejhome.com && \
#     npm config set https-proxy https://npm-cache.matejhome.com

### App config ###

FROM yq AS config_1
USER root
WORKDIR /homelab
COPY ./docker-images/gotify/setup/apps.yml ./docker-images/gotify/setup/users.yml /homelab/
RUN yq '.' '/homelab/apps.yml' >'/homelab/apps.json' && \
    yq '.' '/homelab/users.yml' >'/homelab/users.json'

### App ###

FROM node:26.8.1-slim AS app_build
USER root
WORKDIR /homelab
COPY --from=npmconfig /root/.npmrc /root/.npmrc
COPY ./docker-images/gotify/setup/package-lock.json ./docker-images/gotify/setup/package.json /homelab/
RUN --mount=type=cache,target=/root/.npm,sharing=locked,id=gotify-setup-nodejs-build-npmcache \
    NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error --prefer-offline
COPY ./docker-images/gotify/setup/tsconfig.json /homelab/
COPY ./docker-images/gotify/setup/src/ /homelab/src/
RUN npm run build && \
    npm prune --production

### Healthcheck ###

FROM golang:1.27.0-alpine AS healthcheck-build
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
COPY --from=app_build /homelab/package.json /homelab/
COPY --from=app_build /homelab/dist/ /homelab/dist/
COPY --from=app_build /homelab/node_modules/ /homelab/node_modules/
COPY --from=config_1 /homelab/apps.json /homelab/users.json /homelab/

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
ENV GOTIFY_DEFAULTUSER_NAME="matej" \
    HOMELAB_CONTAINER_NAME=script-setup \
    HOMELAB_CONTAINER_VARIANT=default \
    NODE_OPTIONS=--dns-result-order=ipv4first \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=120s --timeout=1s --retries=1 CMD [ "/homelab/bin/healthcheck", "--file", "/homelab/tmpfs/status.txt", "--content", "started" ]
ENTRYPOINT [ "/nodejs/bin/node", "/homelab/dist/main.js" ]
