# hadolint ignore=DL3002
# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM node:22.5.1-slim AS build
WORKDIR /app
COPY ./custom/webui-backup/package-lock.json ./custom/webui-backup/package.json ./custom/webui-backup/postinstall.sh ./custom/webui-backup/rollup.config.js ./custom/webui-backup/tsconfig.json ./
COPY ./custom/webui-backup/src/ ./src/
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm run build && \
    npm prune --production

FROM node:22.5.1-slim AS prefinal
WORKDIR /app
COPY ./.shared/cron/cron-wrapper.sh ./.shared/cron/entrypoint.sh ./custom/webui-backup/crontab.cron ./custom/webui-backup/main.sh ./custom/webui-backup/package.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist

FROM node:22.5.1-slim
WORKDIR /app
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends chromium cron curl >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /backup /log
COPY --from=prefinal /app /app
ENV TZ=Europe/Bratislava
HEALTHCHECK --interval=60s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /app/.internal/status /dev/stdin >/dev/null 2>&1 || exit 1" ]
STOPSIGNAL SIGKILL
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
