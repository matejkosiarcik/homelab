# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM node:24.6.0-slim AS nodejs-build
WORKDIR /homelab
COPY ./custom/favicons/package-lock.json ./custom/favicons/package.json ./custom/favicons/tsconfig.json ./
COPY ./custom/favicons/src/ ./src/
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm run build && \
    npm prune --production

FROM node:24.6.0-slim AS prefinal
WORKDIR /homelab
COPY --from=nodejs-build /homelab/package.json ./
COPY --from=nodejs-build /homelab/node_modules ./node_modules
COPY --from=nodejs-build /homelab/dist ./dist
COPY ./custom/favicons/icons ./icons

FROM node:24.6.0-slim
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends \
        imagemagick && \
    rm -rf /var/lib/apt/lists/*
ARG UID
ARG GID
RUN groupadd -g $GID user && \
    useradd -m -u $UID -g $GID user
USER user
WORKDIR /homelab
COPY --from=prefinal --chown=user:user /homelab/node_modules ./node_modules
COPY --from=prefinal --chown=user:user /homelab/ ./
ENV HOMELAB_CONTAINER_NAME=favicons \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=30s --timeout=4s CMD [ "sh", "-c", "node /homelab/dist/healthcheck.js || exit 1" ]
STOPSIGNAL SIGKILL
ENTRYPOINT [ "node", "/homelab/dist/main.js" ]
