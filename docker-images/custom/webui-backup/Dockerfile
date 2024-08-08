FROM python:3.12.4-slim AS supercronic-gitman
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

FROM golang:1.22.5-bookworm AS supercronic-build
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

FROM node:22.5.1-slim AS nodejs-build
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
COPY --from=supercronic-build /app/supercronic/supercronic ./bin/
COPY --from=nodejs-build /app/node_modules ./node_modules
COPY --from=nodejs-build /app/dist ./dist

FROM node:22.5.1-slim
WORKDIR /app
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends chromium curl >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /backup /log && \
    groupadd --system homelab && \
    useradd --gid homelab --system homelab && \
    chown -R homelab:homelab /app /backup /log
COPY --from=prefinal --chown=homelab:homelab /app /app
ENV PATH="$PATH:/app/bin" \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=60s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /app/.internal/status /dev/stdin >/dev/null 2>&1 || exit 1" ]
STOPSIGNAL SIGKILL
ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]
