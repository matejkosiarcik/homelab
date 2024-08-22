# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM node:22.6.0-slim AS nodejs-build
WORKDIR /app
COPY ./custom/lamp-network-server/package.json ./custom/lamp-network-server/package-lock.json ./
COPY ./custom/lamp-network-server/patches/ ./patches/
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error
COPY ./custom/lamp-network-server/backend/ ./backend/
COPY ./custom/lamp-network-server/frontend/ ./frontend/
COPY ./custom/lamp-network-server/terser.json ./custom/lamp-network-server/tsconfig.json ./
RUN npm run build && \
    npx modclean --patterns default:safe --run --error-halt && \
    npx node-prune && \
    npm prune --production

FROM debian:12.6-slim AS prefinal
WORKDIR /app
COPY --from=nodejs-build /app/dist/ ./dist/
COPY --from=nodejs-build /app/node_modules/ ./node_modules/
COPY --from=nodejs-build /app/package.json ./

FROM node:22.6.0-slim
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=prefinal /app/ /app/
WORKDIR /app
ENV HOMELAB_CONTAINER_TYPE=lamp-network-server \
    TZ=Europe/Bratislava
EXPOSE 80
EXPOSE 443
HEALTHCHECK --interval=5s --start-period=20s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost/api/status || exit 1" ]
ENTRYPOINT [ "sh", "-c", "node /app/dist/backend/main.js" ]
