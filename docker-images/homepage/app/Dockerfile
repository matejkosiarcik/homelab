# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Build config ###

FROM node:26.10.0-slim AS npmconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_npmconfig_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_npmconfig_aptlibcache \
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

### App ###

FROM node:26.10.0-slim AS nodejs_build
USER root
WORKDIR /homelab
COPY ./docker-images/homepage/app/package-lock.json ./docker-images/homepage/app/package.json /homelab/
COPY --from=npmconfig /root/.npmrc /root/.npmrc
RUN --mount=type=cache,target=/root/.npm,sharing=shared,id=homelab_nodejs_npmcache \
    NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error --prefer-offline
COPY ./docker-images/homepage/app/terser.json ./docker-images/homepage/app/tsconfig.json ./docker-images/homepage/app/vite.config.ts /homelab/
COPY ./docker-images/homepage/app/src/ /homelab/src/
RUN npm run build && \
    npx modclean --patterns default:safe --run --error-halt && \
    npx node-prune && \
    npm prune --production

### Other ###

FROM ghcr.io/gethomepage/homepage:v2.4.0 AS entrypoint
USER root
COPY ./docker-images/homepage/app/entrypoint-extra.sh /homelab/
RUN head -n 1 /usr/local/bin/docker-entrypoint.sh >/homelab/entrypoint-upstream-shebang.sh && \
    tail -n +2 /usr/local/bin/docker-entrypoint.sh >/homelab/entrypoint-upstream-rest.sh && \
    cat /homelab/entrypoint-upstream-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-upstream-rest.sh >/homelab/entrypoint-final.sh && \
    chmod u=rx,go= /homelab/entrypoint-final.sh

FROM ghcr.io/gethomepage/homepage:v2.4.0 AS runtime_dirs
USER root
RUN mkdir -p '/homelab/original/app/.next/server/pages' && \
    cp -R '/app/.next/server/pages/.' '/homelab/original/app/.next/server/pages'

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
USER root
WORKDIR /homelab
COPY ./docker-images/homepage/app/config/ ./config/
COPY --from=nodejs_build /homelab/dist/main.js ./config/custom.js
COPY --from=nodejs_build /homelab/dist/main.css ./config/custom.css
COPY --from=runtime_dirs /homelab/original /homelab/original

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY ./docker-images/homepage/app/icons/ /app/public/icons/
COPY --from=entrypoint /homelab/entrypoint-final.sh /fsroot/entrypoint/docker-entrypoint.sh

### Final ###

FROM ghcr.io/gethomepage/homepage:v2.4.0
USER root
RUN rm -rf /app/.next/server/pages /app/config
COPY --from=prefinal /etc/group /etc/passwd /etc/
RUN chown -R homelab:homelab /app
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /app/public/icons /app/public/icons
COPY --from=prefinal --chown=homelab:homelab /fsroot/entrypoint/docker-entrypoint.sh /usr/local/bin/
ENV HOMELAB_CONTAINER_NAME="homepage" \
    HOMELAB_CONTAINER_VARIANT="default" \
    HOMEPAGE_AUTH_ENABLED="true" \
    HOMEPAGE_AUTH_PASSWORD="" \
    HOMEPAGE_AUTH_SECRET="" \
    HOMEPAGE_MCP_ENABLED="true" \
    TZ="Europe/Bratislava"
USER homelab
