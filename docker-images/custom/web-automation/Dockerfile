# syntax=docker/dockerfile:1

### Build config ###

FROM debian:13.5-slim AS gitconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=web-automation-gitconfig-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=web-automation-gitconfig-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/anticache.txt /homelab/
RUN printf '' >/root/.gitconfig && \
    { curl --fail --silent https://git-cache-github.matejhome.com || exit 0; } && \
    git config --global url."https://git-cache-github.matejhome.com/".insteadOf "https://github.com/"

FROM debian:13.5-slim AS npmconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=web-automation-npmconfig-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=web-automation-npmconfig-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/anticache.txt /homelab/
RUN printf '' >/root/.npmrc && \
    { curl --fail --silent https://npm-cache.matejhome.com || exit 0; } && \
    npm config set proxy https://npm-cache.matejhome.com && \
    npm config set https-proxy https://npm-cache.matejhome.com

### Dependencies ###

FROM python:3.14.5-slim AS gitman
USER root
WORKDIR /homelab
COPY ./.shared/dependencies/gitman/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked,id=web-automation-gitman-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet

### Supercronic ###

FROM python:3.14.5-slim AS supercronic-gitman
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=web-automation-supercronic-gitman-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=web-automation-supercronic-gitman-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/python-vendor /homelab/python-vendor
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./.shared/dependencies/supercronic/gitman.yml /homelab/
COPY --from=gitconfig /root/.gitconfig /root/.gitconfig
RUN --mount=type=cache,target=/root/.cache/git,sharing=locked,id=web-automation-supercronic-gitman-gitcache \
    gitman install --quiet && \
    find . -type d -name .git -prune -exec rm -rf {} \;

FROM golang:1.26.4-trixie AS supercronic-build
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=web-automation-supercronic-build-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=web-automation-supercronic-build-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=supercronic-gitman /homelab/gitman-repositories/supercronic/ ./supercronic/
ENV CGO_ENABLED=0
WORKDIR /homelab/supercronic
RUN go build -ldflags='-s -w -buildid=' -buildvcs=false && \
    strip --strip-all supercronic
WORKDIR /homelab
COPY ./.shared/build-utils/validate-executable.sh /homelab/
RUN sh validate-executable.sh ./supercronic/supercronic

### App ###

FROM node:26.3.0-slim AS nodejs-build
USER root
WORKDIR /homelab
COPY ./custom/web-automation/package-lock.json ./custom/web-automation/package.json ./custom/web-automation/postinstall.sh ./custom/web-automation/rollup.config.js ./custom/web-automation/tsconfig.json /homelab/
COPY ./custom/web-automation/src/ ./src/
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
COPY --from=npmconfig /root/.npmrc /root/.npmrc
RUN --mount=type=cache,target=/root/.npm,sharing=locked,id=web-automation-nodejs-build-npmcache \
    NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm run build && \
    npm prune --production

### Healthcheck ###

FROM golang:1.26.4-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/filecmp-healthcheck/main.go ./.shared/healthchecks/filecmp-healthcheck/go.mod ./.shared/healthchecks/filecmp-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=web-automation-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=web-automation-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Other ###

FROM debian:13.5-slim AS empty-dir
USER root
RUN mkdir /empty

### Users ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.5-slim AS user-setup
USER root
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM node:26.3.0-slim AS browsers
USER root
WORKDIR /homelab
COPY --from=nodejs-build /homelab/package.json /homelab/
COPY --from=nodejs-build /homelab/node_modules /homelab/node_modules
# Cache playwright browsers downloads between versions and rebuilds
# We also have to remove older versions of playwright browsers, to only copy the latest browsers to keep the final size down
# --mount=type=cache,target=/root/.cache/ms-playwright,sharing=locked,id=web-automation-browsers-playwrightcache \
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=web-automation-final-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=web-automation-final-aptlibcache \
    apt-get update -qq && \
    npx --no-install playwright install-deps chromium && \
    npx --no-install playwright install chromium && \
    rm -rf /var/lib/apt/lists/*
    # cp -R /root/.cache/ms-playwright/. /root/.cache-ms-playwright && \
    # find /root/.cache-ms-playwright -mindepth 1 -maxdepth 1 -not -name '.*' | sed 's~^./~~;s~-.*$~~' | sort | uniq | while read -r dir; do \
    #     find /root/.cache-ms-playwright -mindepth 1 -maxdepth 1 -name "$dir"'-*' | sort | head -n -1 | while read -r old_dir; do \
    #         rm -rf "$old_dir" && \
    #     true; done && \
    # true; done

FROM scratch AS homelab-dir
USER root
WORKDIR /homelab
COPY --from=empty-dir /empty /homelab/logs
COPY ./.shared/cron-utils/cron-wrapper.sh ./.shared/cron-utils/entrypoint.sh /homelab/
COPY --from=supercronic-build /homelab/supercronic/supercronic /homelab/bin/
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/
COPY --from=nodejs-build /homelab/package.json /homelab/
COPY --from=nodejs-build /homelab/node_modules /homelab/node_modules
COPY --from=nodejs-build /homelab/dist /homelab/dist
COPY ./custom/web-automation/main.sh /homelab/
COPY ./custom/web-automation/crontab-homeassistant-backup.cron ./custom/web-automation/crontab-omadacontroller-backup.cron ./custom/web-automation/crontab-unificontroller-backup.cron /homelab/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=prefinal /root/.cache-ms-playwright /home/homelab/.cache/ms-playwright
COPY --from=homelab-dir /homelab /homelab

### Final ###

FROM node:26.3.0-slim
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
WORKDIR /homelab
USER homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=web-automation-final-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=web-automation-final-aptlibcache \
    apt-get update -qq && \
    npx --no-install playwright install-deps chromium && \
    rm -rf /var/lib/apt/lists/*
ENV HOMELAB_CONTAINER_NAME=web-automation \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="/homelab/bin:$PATH" \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=30s --timeout=1s CMD [ "/homelab/bin/healthcheck", "--file", "/homelab/tmpfs/status.txt", "--content", "started" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
