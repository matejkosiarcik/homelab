# hadolint ignore=DL3002

FROM node:21.7.3-alpine AS build
WORKDIR /app
COPY main.ts package-lock.json package.json tsconfig.json ./
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --quiet && \
    npm run build && \
    npm prune --production

FROM node:21.7.3-alpine AS aggregator
WORKDIR /app
COPY run.sh entrypoint.sh package.json schedule.cron ./
COPY --from=build /app/dist/main.js ./
COPY --from=build /app/node_modules ./node_modules

# hadolint ignore=DL3002

FROM node:21.7.3-alpine
# hadolint ignore=DL3002
WORKDIR /app
RUN apk update --no-cache && \
    apk add --no-cache chromium curl && \
    mkdir -p /backup /log
COPY --from=aggregator /app /app
# hadolint ignore=DL3002
USER root
# hadolint ignore=DL3002
HEALTHCHECK NONE
VOLUME [ "/backup", "/log" ]
# hadolint ignore=DL3002
ENTRYPOINT [ "sudo", "-E", "sh", "/app/entrypoint.sh" ]
# hadolint ignore=DL3002
