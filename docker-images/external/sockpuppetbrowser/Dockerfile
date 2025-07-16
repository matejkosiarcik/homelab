# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

FROM node:24.4.0-slim AS nodejs-build
WORKDIR /homelab
COPY ./external/sockpuppetbrowser/package-lock.json ./external/sockpuppetbrowser/package.json ./external/sockpuppetbrowser/tsconfig.json ./
COPY ./external/sockpuppetbrowser/src/ ./src/
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm run build && \
    npm prune --production

FROM node:24.4.0-slim AS prefinal
WORKDIR /homelab
COPY --from=nodejs-build /homelab/package.json ./
COPY --from=nodejs-build /homelab/node_modules ./node_modules
COPY --from=nodejs-build /homelab/dist ./dist

FROM dgtlmoon/sockpuppetbrowser:latest
COPY --from=prefinal /homelab/ /homelab/
ENV HOMELAB_CONTAINER_NAME=socket-proxy \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s CMD [ "sh", "-c", "node /homelab/dist/healthcheck.js || exit 1" ]
