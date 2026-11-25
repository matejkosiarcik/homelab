# syntax=docker/dockerfile:1

### Dependencies ###

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS yq
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

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS jinja
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

### Build config ###

FROM node:26.13.1-slim@sha256:abe7e5a82b61a8ef67b315b85497c9e65173387ccf2f4a029248184b8e020be5 AS npmconfig
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

### App config ###

FROM yq AS config_1
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/build-utils/parse-app-entry-utils.sh ./docker-images/healthchecks/setup/extra-entries.yml ./docker-images/healthchecks/setup/parse-app-entry.sh /homelab/
RUN --mount=type=bind,source=./servers/,target=/homelab/servers,readonly \
    --mount=type=bind,source=./docker-compose/,target=/homelab/docker-compose,readonly \
    printf 'apps:\n' >'/homelab/app-entries.yml' && \
    find '/homelab/servers' -path '/homelab/servers/*/docker-apps/*' -mindepth 3 -maxdepth 3 -type d -not -name '.*' -print0 | xargs -0 -I% sh '/homelab/parse-app-entry.sh' % '/homelab/app-entries.yml' && \
    yq --in-place --yaml-output '.apps |= sort_by(.app, .short_name, .full_name, .domain)' '/homelab/app-entries.yml' && \
    cat './app-entries.yml' './extra-entries.yml' >'./all-entries.yml' && \
    yq '.' './all-entries.yml' >'./apps.json'

FROM jinja AS config_2
USER root
WORKDIR /homelab
COPY --from=config_1 /homelab/apps.json /homelab/
COPY ./docker-images/healthchecks/setup/config.yml.j2 /homelab/
RUN jinja2 --strict './config.yml.j2' './apps.json' --format json -o './healthchecks.yml' && \
    if grep --quiet --fixed-strings 'ERROR:' './healthchecks.yml' >/dev/null 2>&1; then \
        printf 'Healthchecks config is not valid:\n' >&2 && \
        cat './healthchecks.yml' >&2 && \
        exit 1; \
    fi

FROM yq AS config_3
USER root
WORKDIR /homelab
COPY --from=config_2 /homelab/healthchecks.yml /homelab/
RUN yq '.' './healthchecks.yml' >'./healthchecks.json'

### App ###

FROM node:26.13.1-slim@sha256:abe7e5a82b61a8ef67b315b85497c9e65173387ccf2f4a029248184b8e020be5 AS app_build
USER root
WORKDIR /homelab
COPY --from=npmconfig /root/.npmrc /root/.npmrc
COPY ./docker-images/healthchecks/setup/package-lock.json ./docker-images/healthchecks/setup/package.json /homelab/
RUN --mount=type=cache,target=/root/.npm,sharing=shared,id=homelab_nodejs_npmcache \
    NODE_OPTIONS=--dns-result-order=ipv4first npm ci --no-audit --no-fund --no-progress --no-save --loglevel=error --prefer-offline
COPY ./docker-images/healthchecks/setup/tsconfig.json /homelab/
COPY ./docker-images/healthchecks/setup/src/ /homelab/src/
RUN npm run build && \
    npx modclean --patterns default:safe --run --error-halt && \
    npx node-prune && \
    npm prune --production

### Healthcheck ###

FROM golang:1.27.4-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280 AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Users ###

FROM gcr.io/distroless/static-debian13:latest@sha256:4c2cd1dee442c9a99924a378c7c126fac8fef14771579ef567c3f2bdd7a5122a AS user_setup_base

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS user_setup
USER root
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
COPY --from=config_3 /homelab/healthchecks.json /homelab/
COPY --from=app_build /homelab/package.json /homelab/
COPY --from=app_build /homelab/dist/ /homelab/dist/
COPY --from=app_build /homelab/node_modules/ /homelab/node_modules/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab

### Final ###

FROM gcr.io/distroless/nodejs26-debian13:latest@sha256:b462e87a3db156aea160dd8a5306b85d02c3061ca0e3194fe0af81282a830ab0 AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
WORKDIR /homelab
ENV HEALTHCHECKS_API_KEY="" \
    HOMELAB_CONTAINER_NAME="script-setup" \
    HOMELAB_CONTAINER_VARIANT="default" \
    NODE_OPTIONS="--dns-result-order=ipv4first" \
    PATH="/homelab/bin:${PATH}" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=2m --timeout=2s --retries=1 CMD [ "healthcheck", "--endpoint", "{\"url\":\"file:///homelab/tmpfs/status.txt\",\"body\":\"started\\n\"}" ]
ENTRYPOINT [ "/nodejs/bin/node", "/homelab/dist/main.js" ]
