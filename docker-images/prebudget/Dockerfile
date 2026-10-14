# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Build config ###

FROM debian:13.7-slim AS gitconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_gitconfig_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_gitconfig_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    printf '' >/root/.gitconfig
# TODO: Re-enable cache below:
# COPY ./docker-images/.shared/anticache.txt /homelab/
# RUN printf '' >/root/.gitconfig && \
#     { curl --fail --silent 'https://git-cache-github.matejhome.com' || exit 0; } && \
#     git config --global 'url.https://git-cache-github.matejhome.com/.insteadOf' 'https://github.com/'

FROM node:26.11.1-slim AS npmconfig
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
#     { curl --fail --silent https://npm-cache.matejhome.com || exit 0; } && \
#     npm config set proxy https://npm-cache.matejhome.com && \
#     npm config set https-proxy https://npm-cache.matejhome.com

### Dependencies ###

FROM python:3.15.0-slim AS gitman
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/dependencies/gitman/requirements.txt /homelab/
ENV PIP_DISABLE_PIP_VERSION_CHECK="1" \
    PIP_ROOT_USER_ACTION="ignore" \
    PYTHONDONTWRITEBYTECODE="1"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --no-compile --requirement './requirements.txt' --target './python-vendor' --quiet

### App ###

FROM node:26.11.1-slim AS nodejs_main_build
USER root
WORKDIR /homelab
COPY ./docker-images/prebudget/package-lock.json ./docker-images/prebudget/package.json /homelab/
COPY --from=npmconfig /root/.npmrc /root/.npmrc
RUN --mount=type=cache,target=/root/.npm,sharing=shared,id=homelab_nodejs_npmcache \
    NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error --prefer-offline
COPY ./docker-images/prebudget/tsconfig.json /homelab/
COPY ./docker-images/prebudget/src/ /homelab/src/
RUN npm run build && \
    npx modclean --patterns default:safe --run --error-halt && \
    npx node-prune && \
    npm prune --production

### Healthcheck ###

FROM golang:1.27.2-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Other ###

FROM debian:13.7-slim AS empty_dir
USER root
RUN mkdir /empty

### Users ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

FROM debian:13.7-slim AS user_setup
USER root
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh '/homelab/create-user.sh' && \
    pwconv && \
    passwd --lock homelab

### Other ###

FROM debian:13.7-slim AS package_ca_certificates
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_package_ca_certificates_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_package_ca_certificates_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates >/dev/null && \
    rm -rf /var/lib/apt/lists/*

### Prefinal ###

FROM scratch AS homelab_dir
USER root
WORKDIR /homelab
COPY --from=empty_dir /empty /homelab/logs
COPY ./docker-images/prebudget/main.sh /homelab/
COPY ./docker-images/prebudget/icons/favicon.png ./docker-images/prebudget/icons/favicon.ico /homelab/icons/
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/
COPY --from=nodejs_main_build /homelab/package.json /homelab/
COPY --from=nodejs_main_build /homelab/node_modules /homelab/node_modules
COPY --from=nodejs_main_build /homelab/dist /homelab/dist

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=package_ca_certificates /etc/ssl/certs/ca-certificates.crt /fsroot/certs/

### Final ###

FROM node:26.11.1-slim AS final
LABEL build.user=matejkosiarcik
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/certs /etc/ssl/certs
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME="prebudget" \
    HOMELAB_CONTAINER_VARIANT="default" \
    HOMELAB_CRON_SKIP_INITIAL="1" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=300s --timeout=4s CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:8080/.health" ]
ENTRYPOINT [ "/bin/sh", "/homelab/main.sh" ]
