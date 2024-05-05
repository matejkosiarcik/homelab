# hadolint ignore=DL3002
# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM node:22.1.0-alpine AS build
WORKDIR /app
COPY main.ts package-lock.json package.json tsconfig.json ./
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --quiet && \
    npm run build && \
    npm prune --production

FROM node:22.1.0-alpine AS aggregator
WORKDIR /app
COPY main.sh package.json schedule.cron ./
COPY --from=build /app/dist/main.js ./
COPY --from=build /app/node_modules ./node_modules

FROM node:22.1.0-alpine
WORKDIR /app
RUN apk update --no-cache && \
    apk add --no-cache chromium curl && \
    adduser -h /home/user -s /bin/sh -D user && \
    mkdir -p /backup /log
COPY --from=aggregator /app /app
HEALTHCHECK --interval=30s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /app/.internal/status /dev/stdin >/dev/null 2>&1 || exit 1" ]
# TODO: Update to --interval=10s --start-period=25s
STOPSIGNAL SIGKILL
VOLUME [ "/backup", "/log" ]
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
