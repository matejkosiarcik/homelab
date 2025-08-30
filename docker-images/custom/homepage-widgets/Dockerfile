# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM node:24.7.0-slim AS nodejs-build
WORKDIR /homelab
COPY ./custom/homepage-widgets/package-lock.json ./custom/homepage-widgets/package.json ./custom/homepage-widgets/tsconfig.json ./
COPY ./custom/homepage-widgets/src/ ./src/
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm run build && \
    npm prune --production

FROM node:24.7.0-slim AS prefinal
WORKDIR /homelab
COPY --from=nodejs-build /homelab/package.json ./
COPY --from=nodejs-build /homelab/node_modules ./node_modules
COPY --from=nodejs-build /homelab/dist ./dist

FROM node:24.7.0-slim
ARG UID=1999
ARG GID=1999
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab && \
    chown -R user:user /homelab
WORKDIR /homelab
COPY --from=prefinal --chown=user:user /homelab/node_modules ./node_modules
COPY --from=prefinal --chown=user:user /homelab/ ./
ENV HOMELAB_CONTAINER_NAME=homepage-widgets \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER user
HEALTHCHECK --interval=10s --start-period=30s --timeout=1s CMD [ "sh", "-c", "node /homelab/dist/healthcheck.js || exit 1" ]
STOPSIGNAL SIGKILL
ENTRYPOINT [ "node", "/homelab/dist/main.js" ]
