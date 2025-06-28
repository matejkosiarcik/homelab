# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM node:24.3.0-slim AS nodejs-build
WORKDIR /homelab
COPY ./custom/homepage-widget-prometheus/package-lock.json ./custom/homepage-widget-prometheus/package.json ./custom/homepage-widget-prometheus/tsconfig.json ./
COPY ./custom/homepage-widget-prometheus/src/ ./src/
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm run build && \
    npm prune --production

FROM node:24.3.0-slim AS prefinal
WORKDIR /homelab
COPY --from=nodejs-build /homelab/package.json ./
COPY --from=nodejs-build /homelab/node_modules ./node_modules
COPY --from=nodejs-build /homelab/dist ./dist

FROM node:24.3.0-slim
WORKDIR /homelab
COPY --from=prefinal /homelab/node_modules ./node_modules
COPY --from=prefinal /homelab/ ./
ENV HOMELAB_CONTAINER_NAME=homepage-widget-prometheus \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=30s --timeout=1s CMD [ "sh", "-c", "node ./dist/healthcheck.js || exit 1" ]
STOPSIGNAL SIGKILL
ENTRYPOINT [ "node", "/homelab/dist/main.js" ]
