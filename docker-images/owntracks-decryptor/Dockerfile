# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Build config ###

FROM debian:13.5-slim AS npmconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=owntracks-decryptor-npmconfig-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=owntracks-decryptor-npmconfig-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/anticache.txt /homelab/
RUN printf '' >/root/.npmrc && \
    { curl --fail --silent https://npm-cache.matejhome.com || exit 0; } && \
    npm config set proxy https://npm-cache.matejhome.com && \
    npm config set https-proxy https://npm-cache.matejhome.com

### App ###

FROM node:26.3.0-slim AS nodejs-build
USER root
WORKDIR /homelab
COPY ./docker-images/owntracks-decryptor/package-lock.json ./docker-images/owntracks-decryptor/package.json ./docker-images/owntracks-decryptor/tsconfig.json /homelab/
COPY ./docker-images/owntracks-decryptor/src/ /homelab/src/
COPY --from=npmconfig /root/.npmrc /root/.npmrc
RUN --mount=type=cache,target=/root/.npm,sharing=locked,id=owntracks-decryptor-nodejs-build-npmcache \
    NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm run build && \
    npm prune --production

### Healthcheck ###

FROM golang:1.26.4-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=owntracks-decryptor-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=owntracks-decryptor-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Users ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.5-slim AS user-setup
USER root
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
USER root
WORKDIR /homelab
COPY --from=nodejs-build /homelab/package.json /homelab/
COPY --from=nodejs-build /homelab/node_modules /homelab/node_modules
COPY --from=nodejs-build /homelab/dist /homelab/dist
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/nodejs26-debian13:latest
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME=owntracks-decryptor \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=4s CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:8080/.health" ]
ENTRYPOINT [ "/nodejs/bin/node", "/homelab/dist/main.js" ]
