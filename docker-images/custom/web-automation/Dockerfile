FROM python:3.13.7-slim AS supercronic-gitman
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/dependencies/gitman/requirements.txt ./
ENV PIP_ROOT_USER_ACTION=ignore
RUN python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./.shared/dependencies/supercronic/gitman.yml ./
RUN gitman install --quiet && \
    find . -type d -name .git -prune -exec rm -rf {} \;

FROM golang:1.25.1-bookworm AS supercronic-build
WORKDIR /homelab
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=supercronic-gitman /homelab/gitman-repositories/supercronic/ ./supercronic/
ENV CGO_ENABLED=0
WORKDIR /homelab/supercronic
RUN go build -ldflags='-s -w -buildid=' -buildvcs=false && \
    strip --strip-all supercronic
WORKDIR /homelab
COPY ./.shared/build-utils/validate-executable.sh ./
RUN sh validate-executable.sh ./supercronic/supercronic

FROM debian:13.0-slim AS supercronic
WORKDIR /homelab
RUN mkdir -p ./certs ./logs
COPY ./.shared/cron-utils/cron-wrapper.sh ./.shared/cron-utils/entrypoint.sh ./
COPY --from=supercronic-build /homelab/supercronic/supercronic ./bin/
ENV PATH="/homelab/bin:$PATH"

FROM node:24.7.0-slim AS nodejs-build
WORKDIR /homelab
COPY ./custom/web-automation/package-lock.json ./custom/web-automation/package.json ./custom/web-automation/postinstall.sh ./custom/web-automation/rollup.config.js ./custom/web-automation/tsconfig.json ./
COPY ./custom/web-automation/src/ ./src/
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
RUN NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm run build && \
    npm prune --production

FROM node:24.7.0-slim AS prefinal
WORKDIR /homelab
COPY --from=supercronic /homelab/ ./
COPY --from=nodejs-build /homelab/package.json ./
COPY --from=nodejs-build /homelab/node_modules ./node_modules
# Cache playwright browsers downloads between versions and rebuilds
# We also have to remove older versions of playwright browsers, to only copy the latest browsers to keep the final size down
RUN --mount=type=cache,target=/root/.cache/ms-playwright \
    apt-get update && \
    npx --no-install playwright install-deps chromium && \
    npx --no-install playwright install chromium && \
    rm -rf /var/lib/apt/lists/* && \
    cp -R /root/.cache/ms-playwright/. /root/.cache-ms-playwright && \
    find /root/.cache-ms-playwright -mindepth 1 -maxdepth 1 -not -name '.*' | sed 's~^./~~;s~-.*$~~' | sort | uniq | while read -r dir; do \
        find /root/.cache-ms-playwright -mindepth 1 -maxdepth 1 -name "$dir"'-*' | sort | head -n -1 | while read -r old_dir; do \
            rm -rf "$old_dir" && \
        true; done && \
    true; done && \
    mkdir -p /backup /log
COPY --from=nodejs-build /homelab/dist ./dist
COPY ./custom/web-automation/main.sh ./
COPY ./custom/web-automation/crontab-homeassistant-backup.cron ./custom/web-automation/crontab-omadacontroller-backup.cron ./custom/web-automation/crontab-unificontroller-backup.cron ./

FROM node:24.7.0-slim
ARG UID=1000
ARG GID=1000
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab && \
    chown -R user:user /homelab
WORKDIR /homelab
COPY --from=prefinal --chown=user:user /homelab/node_modules ./node_modules
USER user
RUN apt-get update && \
    npx --no-install playwright install-deps chromium && \
    rm -rf /var/lib/apt/lists/*
COPY --from=prefinal --chown=user:user /homelab/ ./
COPY --from=prefinal --chown=user:user /root/.cache-ms-playwright /home/user/.cache/ms-playwright
ENV HOMELAB_CONTAINER_NAME=web-automation \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="/homelab/bin:$PATH" \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=30s --timeout=1s CMD [ "sh", "-c", "printf 'started\n' | cmp /homelab/.status/status.txt /dev/stdin >/dev/null 2>&1 || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
