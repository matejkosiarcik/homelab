FROM node:21.7.0-alpine AS build
WORKDIR /app
COPY main.ts package-lock.json package.json tsconfig.json ./
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --quiet && \
    npm run build && \
    npm prune --production

FROM node:21.7.0-alpine AS aggregator
WORKDIR /app
COPY run.sh entrypoint.sh package.json schedule.cron ./
COPY --from=build /app/dist/main.js ./
COPY --from=build /app/node_modules ./node_modules

FROM node:21.7.0-alpine
WORKDIR /app
RUN mkdir -p /backup /log && \
    apk add --no-cache chromium
COPY --from=aggregator /app /app
VOLUME [ "/backup", "/log" ]
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
