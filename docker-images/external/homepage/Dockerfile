# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in

FROM debian:13.2-slim AS npmconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/date.txt ./
RUN printf '' >/root/.npmrc && \
    { curl --fail --silent https://npm-cache.matejhome.com || exit 0; } && \
    npm config set proxy https://npm-cache.matejhome.com && \
    npm config set https-proxy https://npm-cache.matejhome.com

FROM node:25.2.1-slim AS nodejs-build
USER root
WORKDIR /homelab
COPY ./external/homepage/package-lock.json ./external/homepage/package.json ./external/homepage/terser.json ./external/homepage/tsconfig.json ./external/homepage/vite.config.ts ./
COPY ./external/homepage/src/ ./src/
COPY --from=npmconfig /root/.npmrc /root/.npmrc
RUN --mount=type=cache,target=/root/.npm \
    NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm run build && \
    npm prune --production

FROM debian:13.2-slim AS prefinal
USER root
WORKDIR /homelab
COPY ./external/homepage/config/ ./config/
COPY --from=nodejs-build /homelab/dist/main.js ./config/custom.js
COPY --from=nodejs-build /homelab/dist/main.css ./config/custom.css

FROM ghcr.io/gethomepage/homepage:v1.8.0
USER root
RUN mkdir -p /homelab/app-pages && \
    find /app/.next/server/pages -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/app/.next/server/pages/$(basename "$1")" "/homelab/app-pages/$(basename "$1")"' - {} \; && \
    rm -rf /app/.next/server/pages
COPY ./external/homepage/entrypoint-extra.sh /homelab/
RUN mkdir -p /homelab && \
    head -n 1 /usr/local/bin/docker-entrypoint.sh >/homelab/entrypoint-shebang.sh && \
    tail -n +2 /usr/local/bin/docker-entrypoint.sh >/homelab/entrypoint-without-shebang.sh && \
    cat /homelab/entrypoint-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-without-shebang.sh >/usr/local/bin/docker-entrypoint.sh && \
    rm -rf /app/config /homelab/entrypoint-extra.sh
ARG GID=1000
ARG UID=1000
RUN if [ "$(getent group "$GID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
        groupadd --gid "$GID" homelab && \
    true; else \
        oldgroupname="$(getent group "$GID" | cut -d: -f1)" && \
        groupmod --new-name homelab "$oldgroupname" && \
    true; fi && \
    nologinshell='' && \
    if [ -e /sbin/nologin ]; then \
        nologinshell='/sbin/nologin' && \
    true; elif [ -e /usr/sbin/nologin ]; then \
        nologinshell='/usr/sbin/nologin' && \
    true; else \
        nologinshell='/bin/false' && \
    true; fi && \
    if [ "$(getent passwd "$UID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
        useradd --no-log-init --home /home/homelab --uid "$UID" --gid "$GID" --shell "$nologinshell" homelab && \
    true; else \
        oldusername="$(getent passwd "$UID" | cut -d: -f1)" && \
        usermod --move-home --home /home/homelab --uid "$UID" --gid "$GID" --shell "$nologinshell" --login homelab "$oldusername" && \
    true; fi && \
    mkdir -p /home/homelab /homelab && \
    chown -R homelab:homelab /home/homelab /homelab /app
COPY --chown=homelab:homelab ./external/homepage/icons/ /app/public/icons/
COPY --from=prefinal --chown=homelab:homelab /homelab/config/ /homelab/app-config/
ENV HOMELAB_CONTAINER_NAME=homepage \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER homelab
