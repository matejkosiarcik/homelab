# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM python:3.12.5-slim AS supercronic-gitman
WORKDIR /app
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.dependencies/gitman/requirements.txt ./
RUN python3 -m pip install --requirement requirements.txt --target python-packages --quiet
ENV PATH="/app/python-packages/bin:$PATH" \
    PYTHONPATH=/app/python-packages
COPY ./.dependencies/supercronic/gitman.yml ./
RUN gitman install --quiet

FROM golang:1.23.0-bookworm AS supercronic-build
WORKDIR /app
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=supercronic-gitman /app/gitman-repositories/supercronic/ ./supercronic/
ENV CGO_ENABLED=0
WORKDIR /app/supercronic
RUN go build -ldflags='-s -w -buildid=' -buildvcs=false && \
    strip --strip-all supercronic
WORKDIR /app
COPY ./.shared/build-utils/validate-executable.sh ./
RUN sh validate-executable.sh ./supercronic/supercronic

FROM node:22.6.0-slim AS nodejs-build
WORKDIR /app
COPY ./custom/web-automation/package-lock.json ./custom/web-automation/package.json ./custom/web-automation/postinstall.sh ./custom/web-automation/rollup.config.js ./custom/web-automation/tsconfig.json ./
COPY ./custom/web-automation/src/ ./src/
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm run build && \
    npm prune --production

FROM node:22.6.0-slim AS prefinal
WORKDIR /app
COPY --from=nodejs-build /app/package.json ./
COPY --from=nodejs-build /app/node_modules ./node_modules
RUN apt-get update && \
    npx --no-install playwright install-deps chromium && \
    npx --no-install playwright install chromium && \
    rm -rf /var/lib/apt/lists/*
COPY --from=nodejs-build /app/dist ./dist
COPY ./.shared/cron-utils/cron-wrapper.sh ./.shared/cron-utils/entrypoint.sh ./custom/web-automation/crontab-backup.cron ./custom/web-automation/crontab-other.cron ./custom/web-automation/main.sh ./
COPY --from=supercronic-build /app/supercronic/supercronic ./bin/

FROM node:22.6.0-slim
WORKDIR /app
RUN mkdir -p /backup /log
COPY --from=prefinal /app/node_modules ./node_modules
RUN apt-get update && \
    npx --no-install playwright install-deps chromium && \
    rm -rf /var/lib/apt/lists/*
COPY --from=prefinal /app /app
COPY --from=prefinal /root/.cache/ms-playwright /root/.cache/ms-playwright
ENV HOMELAB_CONTAINER_TYPE=web-automation \
    PATH="$PATH:/app/bin" \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=60s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /app/.internal/status /dev/stdin >/dev/null 2>&1 || exit 1" ]
STOPSIGNAL SIGKILL
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
