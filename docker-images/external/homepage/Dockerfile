# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in

FROM node:24.4.1-slim AS nodejs-build
WORKDIR /homelab
COPY ./external/homepage/package-lock.json ./external/homepage/package.json ./external/homepage/terser.json ./external/homepage/tsconfig.json ./external/homepage/vite.config.ts ./
COPY ./external/homepage/src/ ./src/
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm run build && \
    npm prune --production

FROM debian:12.11-slim AS prefinal
WORKDIR /homelab
COPY ./external/homepage/config/ ./config/
COPY --from=nodejs-build /homelab/dist/main.js ./config/custom.js
COPY --from=nodejs-build /homelab/dist/main.css ./config/custom.css

FROM ghcr.io/gethomepage/homepage:v1.4.0
COPY --from=prefinal /homelab/config/ /app/config/
COPY ./external/homepage/icons/ /app/public/icons/
ENV HOMELAB_CONTAINER_NAME=homepage \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
