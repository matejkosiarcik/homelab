# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in

FROM node:24.6.0-slim AS nodejs-build
WORKDIR /homelab
COPY ./external/homepage/package-lock.json ./external/homepage/package.json ./external/homepage/terser.json ./external/homepage/tsconfig.json ./external/homepage/vite.config.ts ./
COPY ./external/homepage/src/ ./src/
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm run build && \
    npm prune --production

FROM debian:13.0-slim AS prefinal
WORKDIR /homelab
COPY ./external/homepage/config/ ./config/
COPY --from=nodejs-build /homelab/dist/main.js ./config/custom.js
COPY --from=nodejs-build /homelab/dist/main.css ./config/custom.css

FROM ghcr.io/gethomepage/homepage:v1.4.5
RUN mkdir -p /homelab/app-pages && \
    find /app/.next/server/pages -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/app/.next/server/pages/$(basename "$1")" "/homelab/app-pages/$(basename "$1")"' - {} \; && \
    rm -rf /app/.next/server/pages
COPY --from=prefinal /homelab/config/ /homelab/app-config/
COPY ./external/homepage/docker-entrypoint-extra.sh /homelab/
RUN head -n 1 /usr/local/bin/docker-entrypoint.sh >/homelab/docker-entrypoint-shebang.sh && \
    tail -n +2 /usr/local/bin/docker-entrypoint.sh >/homelab/docker-entrypoint-without-shebang.sh && \
    cat /homelab/docker-entrypoint-shebang.sh /homelab/docker-entrypoint-extra.sh /homelab/docker-entrypoint-without-shebang.sh >/usr/local/bin/docker-entrypoint.sh && \
    rm -rf /app/config
COPY ./external/homepage/icons/ /app/public/icons/
ENV HOMELAB_CONTAINER_NAME=homepage \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
