# hadolint ignore=DL3002
# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM node:22.5.1-slim AS build
WORKDIR /app
COPY package-lock.json package.json postinstall.sh tsconfig.json ./
COPY src/ ./src/
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm run build && \
    npm prune --production

FROM node:22.5.1-slim AS aggregator
WORKDIR /app
COPY package.json schedule.cron tsconfig.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY entrypoint.sh ./entrypoint.sh
COPY run.sh ./run.sh

FROM node:22.5.1-slim
WORKDIR /app
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends chromium cron curl >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /backup /log
COPY --from=aggregator /app /app
ENV TZ=Europe/Bratislava
HEALTHCHECK --interval=60s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /app/.internal/status /dev/stdin >/dev/null 2>&1 || exit 1" ]
VOLUME [ "/backup", "/log" ]
STOPSIGNAL SIGKILL
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
