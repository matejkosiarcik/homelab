# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM node:23.2.0-slim AS nodejs-build
WORKDIR /homelab
COPY ./custom/lamp-wrapper/package.json ./custom/lamp-wrapper/package-lock.json ./
COPY ./custom/lamp-wrapper/patches/ ./patches/
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error
COPY ./custom/lamp-wrapper/src/ ./src/
COPY ./custom/lamp-wrapper/rollup.config.js ./custom/lamp-wrapper/terser.json ./custom/lamp-wrapper/tsconfig.json ./
RUN npm run build && \
    npx modclean --patterns default:safe --run --error-halt && \
    npx node-prune && \
    npm prune --production

FROM debian:12.8-slim AS prefinal
WORKDIR /homelab
COPY --from=nodejs-build /homelab/dist/ ./dist/
COPY --from=nodejs-build /homelab/node_modules/ ./node_modules/
COPY --from=nodejs-build /homelab/package.json ./

FROM node:23.2.0-slim
WORKDIR /homelab
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=prefinal /homelab/ ./
ENV HOMELAB_CONTAINER_NAME=lamp-wrapper \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost/api/.wrapper/health || exit 1" ]
ENTRYPOINT [ "sh", "-c", "node /homelab/dist/main.js" ]
