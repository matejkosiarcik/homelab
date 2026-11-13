# syntax=docker/dockerfile:1

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
COPY ./docker-images/owntracks-decryptor/package-lock.json ./docker-images/owntracks-decryptor/package.json /homelab/
COPY --from=npmconfig /root/.npmrc /root/.npmrc
RUN --mount=type=cache,target=/root/.npm,sharing=shared,id=homelab_nodejs_npmcache \
    NODE_OPTIONS=--dns-result-order=ipv4first npm ci --no-progress --no-audit --no-fund --loglevel=error --prefer-offline
COPY ./docker-images/owntracks-decryptor/tsconfig.json /homelab/
COPY ./docker-images/owntracks-decryptor/src/ /homelab/src/
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

### Users ###

FROM gcr.io/distroless/static-debian13:latest@sha256:1a64f46364620465ef9e9a8f5413757dfdf22695e050bbfd7303eeaf17a59383 AS user_setup_base

FROM debian:13.7-slim AS user_setup
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
COPY --from=nodejs_build /homelab/package.json /homelab/
COPY --from=nodejs_build /homelab/node_modules /homelab/node_modules
COPY --from=nodejs_build /homelab/dist /homelab/dist
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab

### Final ###

FROM gcr.io/distroless/nodejs26-debian13:latest@sha256:80631bd2f0e7ef192138a7409013b47d92fd11b8ff3bb35f5c0a65be3ecaea4c AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME="owntracks-decryptor" \
    HOMELAB_CONTAINER_VARIANT="default" \
    NODE_OPTIONS="--dns-result-order=ipv4first" \
    SECRET_KEY="" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:8080/.health" ]
ENTRYPOINT [ "/nodejs/bin/node", "/homelab/dist/main.js" ]
