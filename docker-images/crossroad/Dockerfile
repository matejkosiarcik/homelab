# syntax=docker/dockerfile:1

### Dependencies ###

FROM debian:13.7-slim AS yq
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_yq_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_yq_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/yq/requirements.txt /homelab/
ENV PIP_DISABLE_PIP_VERSION_CHECK="1" \
    PIP_ROOT_USER_ACTION="ignore" \
    PYTHONDONTWRITEBYTECODE="1"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --quiet --no-compile --require-hashes --requirement './requirements.txt' --target './python-vendor'
ENV PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"

FROM debian:13.7-slim AS jinja
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_jinja_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_jinja_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/jinja/requirements.txt /homelab/
ENV PIP_DISABLE_PIP_VERSION_CHECK="1" \
    PIP_ROOT_USER_ACTION="ignore" \
    PYTHONDONTWRITEBYTECODE="1"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --quiet --no-compile --require-hashes --requirement './requirements.txt' --target './python-vendor'
ENV PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"

### App config ###

FROM yq AS monitoring_entries
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/build-utils/parse-app-entry-utils.sh ./docker-images/crossroad/parse-app-entry.sh /homelab/
RUN --mount=type=bind,source=./servers/,target=/homelab/servers,readonly \
    --mount=type=bind,source=./docker-compose/,target=/homelab/docker-compose,readonly \
    printf 'apps:\n' >'/homelab/app-entries.yml' && \
    find '/homelab/servers' -path '/homelab/servers/*/docker-apps/*' -mindepth 3 -maxdepth 3 -type d -not -name '.*' -print0 | xargs -0 -I% sh '/homelab/parse-app-entry.sh' % '/homelab/app-entries.yml' && \
    yq --in-place --yaml-output '.apps |= sort_by(.app, .short_name, .full_name, .domain)' '/homelab/app-entries.yml'
ARG CROSSROAD_TYPE="placeholder"
# hadolint ignore=SC2016
RUN yq --exit-status --arg crossroad_type "${CROSSROAD_TYPE}" 'any(.apps[]; .app_type == $crossroad_type or (.app_type | startswith($crossroad_type + "-")))' '/homelab/app-entries.yml' >/dev/null && \
    yq --in-place --yaml-output --arg crossroad_type "${CROSSROAD_TYPE}" '.apps |= map(select(.app_type == $crossroad_type or (.app_type | startswith($crossroad_type + "-"))))' '/homelab/app-entries.yml' && \
    yq '.' '/homelab/app-entries.yml' >'/homelab/apps.json'

FROM jinja AS homepage_config
USER root
WORKDIR /homelab
COPY --from=monitoring_entries /homelab/apps.json /homelab/
COPY ./docker-images/crossroad/config/app/services.yaml.j2 /homelab/
RUN jinja2 --strict './services.yaml.j2' './apps.json' --format json -o './services.yaml'

### Build config ###

FROM node:26.13.1-slim AS npmconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_npmconfig_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_npmconfig_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    touch '/root/.npmrc'
# TODO: Re-enable cache below:
# COPY ./docker-images/.shared/anticache.txt /homelab/
# RUN touch '/root/.npmrc' && \
#     { curl --fail --silent https://npmcache.matejhome.com || exit 0; } && \
#     npm config set proxy https://npmcache.matejhome.com && \
#     npm config set https-proxy https://npmcache.matejhome.com

### App ###

FROM node:26.13.1-slim AS nodejs_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/homepage-helpers/package-lock.json ./docker-images/.shared/homepage-helpers/package.json /homelab/
COPY --from=npmconfig /root/.npmrc /root/.npmrc
RUN --mount=type=cache,target=/root/.npm,sharing=shared,id=homelab_nodejs_npmcache \
    NODE_OPTIONS=--dns-result-order=ipv4first npm ci --no-progress --no-audit --no-fund --loglevel=error --prefer-offline
COPY ./docker-images/.shared/homepage-helpers/terser.json ./docker-images/.shared/homepage-helpers/tsconfig.json ./docker-images/.shared/homepage-helpers/vite.config.ts /homelab/
COPY ./docker-images/.shared/homepage-helpers/src/ /homelab/src/
RUN npm run build && \
    npx modclean --patterns default:safe --run --error-halt && \
    npx node-prune && \
    npm prune --production

### Healthcheck ###

FROM golang:1.27.4-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Other ###

FROM debian:13.7-slim AS empty_dir
USER root
RUN mkdir /empty && \
    touch /empty.txt

FROM ghcr.io/gethomepage/homepage:v2.8.0 AS entrypoint
USER root
COPY ./docker-images/crossroad/entrypoint-extra.sh /homelab/
RUN head -n 1 /usr/local/bin/docker-entrypoint.sh >/homelab/entrypoint-upstream-shebang.sh && \
    tail -n +2 /usr/local/bin/docker-entrypoint.sh >/homelab/entrypoint-upstream-rest.sh && \
    cat /homelab/entrypoint-upstream-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-upstream-rest.sh >/homelab/entrypoint-final.sh && \
    chmod u=rx,go= /homelab/entrypoint-final.sh

FROM ghcr.io/gethomepage/homepage:v2.8.0 AS runtime_dirs
USER root
RUN mkdir -p '/homelab/original/app/.next/server/pages' && \
    cp -R '/app/.next/server/pages/.' '/homelab/original/app/.next/server/pages'

### User setup ###

FROM gcr.io/distroless/static-debian13:latest@sha256:448810357cc8e67b7208988abdba0f5ec3d3aebee0a5b13eb624979792cffc0f AS user_setup_base

FROM debian:13.7-slim AS user_setup
USER root
WORKDIR /homelab
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh '/homelab/create-user.sh' && \
    pwconv && \
    passwd --lock homelab

### Prefinal ###

FROM scratch AS homelab_dir
USER root
WORKDIR /homelab
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/
COPY ./docker-images/crossroad/config/general/ /homelab/config/
COPY --from=homepage_config /homelab/services.yaml /homelab/config/services.yaml
COPY --from=nodejs_build /homelab/dist/main.js /homelab/config/custom.js
COPY --from=nodejs_build /homelab/dist/main.css /homelab/config/custom.css
COPY --from=runtime_dirs /homelab/original /homelab/original

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=entrypoint /homelab/entrypoint-final.sh /fsroot/entrypoint/docker-entrypoint.sh
ARG CROSSROAD_TYPE="placeholder"
COPY ./docker-images/crossroad/icons/${CROSSROAD_TYPE}/ /app/public/icons/
COPY ./docker-images/crossroad/favicon/ /app/public/icons/favicon/
COPY --from=empty_dir /empty /app/config/logs

### Final ###

FROM ghcr.io/gethomepage/homepage:v2.8.0 AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
RUN rm -rf /app/.next/server/pages /app/config /app/config/logs
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
RUN chown -R homelab:homelab /app
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /app/public/icons /app/public/icons
COPY --from=prefinal --chown=homelab:homelab /fsroot/entrypoint/docker-entrypoint.sh /usr/local/bin/
COPY --from=prefinal --chown=homelab:homelab /app/config/logs /app/config/logs
ENV HOMELAB_CONTAINER_NAME="crossroad" \
    HOMELAB_CONTAINER_VARIANT="default" \
    HOMEPAGE_AUTH_ENABLED="false" \
    HOMEPAGE_AUTH_PASSWORD="" \
    HOMEPAGE_AUTH_SECRET="" \
    HOMEPAGE_MCP_ENABLED="false" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "exec /homelab/bin/healthcheck --url \"http://localhost:${PORT}/api/healthcheck\" --status '200' --body-regex '^up'" ]
