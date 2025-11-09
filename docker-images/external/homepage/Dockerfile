# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in

FROM node:25.1.0-slim AS nodejs-build
WORKDIR /homelab
COPY ./external/homepage/package-lock.json ./external/homepage/package.json ./external/homepage/terser.json ./external/homepage/tsconfig.json ./external/homepage/vite.config.ts ./
COPY ./external/homepage/src/ ./src/
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm run build && \
    npm prune --production

FROM debian:13.1-slim AS prefinal
WORKDIR /homelab
COPY ./external/homepage/config/ ./config/
COPY --from=nodejs-build /homelab/dist/main.js ./config/custom.js
COPY --from=nodejs-build /homelab/dist/main.css ./config/custom.css

FROM ghcr.io/gethomepage/homepage:v1.6.1
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
