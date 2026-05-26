### Config ###

FROM debian:13.2-slim AS npmconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/date.txt /homelab/
RUN printf '' >/root/.npmrc && \
    { curl --fail --silent https://npm-cache.matejhome.com || exit 0; } && \
    npm config set proxy https://npm-cache.matejhome.com && \
    npm config set https-proxy https://npm-cache.matejhome.com

### App ###

FROM node:25.2.1-slim AS nodejs-build
USER root
WORKDIR /homelab
COPY ./external/homepage/package-lock.json ./external/homepage/package.json ./external/homepage/terser.json ./external/homepage/tsconfig.json ./external/homepage/vite.config.ts /homelab/
COPY ./external/homepage/src/ ./src/
COPY --from=npmconfig /root/.npmrc /root/.npmrc
RUN --mount=type=cache,target=/root/.npm \
    NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm run build && \
    npm prune --production

### Other ###

FROM ghcr.io/gethomepage/homepage:v1.8.0 AS entrypoint
USER root
COPY ./external/homepage/entrypoint-extra.sh /homelab/
RUN head -n 1 /usr/local/bin/docker-entrypoint.sh >/homelab/entrypoint-shebang.sh && \
    tail -n +2 /usr/local/bin/docker-entrypoint.sh >/homelab/entrypoint-without-shebang.sh && \
    cat /homelab/entrypoint-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-without-shebang.sh >/usr/local/bin/docker-entrypoint.sh

FROM ghcr.io/gethomepage/homepage:v1.8.0 AS runtime-dirs
USER root
RUN mkdir -p /homelab/original/app/.next/server/pages && \
    cp -R /app/.next/server/pages/. /homelab/original/app/.next/server/pages

### User setup ###

FROM gcr.io/distroless/static-debian13 AS user-setup-base

FROM debian:13.2-slim AS user-setup
USER root
WORKDIR /homelab
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM debian:13.2-slim AS homelab-dir
USER root
WORKDIR /homelab
COPY ./external/homepage/config/ ./config/
COPY --from=nodejs-build /homelab/dist/main.js ./config/custom.js
COPY --from=nodejs-build /homelab/dist/main.css ./config/custom.css
COPY --from=runtime-dirs /homelab/original /homelab/original

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY ./external/homepage/icons/ /app/public/icons/
COPY --from=entrypoint /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

### Final ###

FROM ghcr.io/gethomepage/homepage:v1.8.0
USER root
RUN rm -rf /app/.next/server/pages /app/config
COPY --from=prefinal /etc/group /etc/passwd /etc/
RUN chown -R homelab:homelab /app
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /app/public/icons /app/public/icons
COPY --from=prefinal --chown=homelab:homelab /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENV HOMELAB_CONTAINER_NAME=homepage \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER homelab
