# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Build config ###

FROM debian:13.5-slim AS gitconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=favicons-gitconfig-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=favicons-gitconfig-aptlibcache \
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
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=favicons-npmconfig-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=favicons-npmconfig-aptlibcache \
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
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked,id=favicons-gitman-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet

FROM python:3.14.5-slim AS imagemagick-appimage-gitman
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=favicons-imagemagick-appimage-gitman-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=favicons-imagemagick-appimage-gitman-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/python-vendor /homelab/python-vendor
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./.shared/dependencies/imagemagick-appimage/gitman.yml /homelab/
COPY --from=gitconfig /root/.gitconfig /root/.gitconfig
RUN --mount=type=cache,target=/root/.cache/git,sharing=locked,id=favicons-imagemagick-appimage-gitman-gitcache \
    gitman install --quiet

FROM debian:13.5-slim AS imagemagick-final
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=favicons-imagemagick-final-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=favicons-imagemagick-final-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=imagemagick-appimage-gitman /homelab/gitman-repositories/imagemagick-appimage /homelab/imagemagick-git
WORKDIR /homelab/imagemagick-git
RUN version="$(cat LATEST_VERSION)" && \
    tag="$(git tag --list "${version}@*")" && \
    curl --silent -L -o ./ImageMagick.AppImage "https://github.com/pkgforge-dev/ImageMagick-AppImage/releases/download/${tag}/ImageMagick-${version}-anylinux-$(uname -m).AppImage" && \
    chmod a+x ./ImageMagick.AppImage && \
    ./ImageMagick.AppImage --appimage-extract && \
    mv ./AppDir /homelab/imagemagick

### App ###

FROM node:26.3.0-slim AS nodejs-build
USER root
WORKDIR /homelab
COPY ./custom/favicons/package-lock.json ./custom/favicons/package.json ./custom/favicons/tsconfig.json /homelab/
COPY ./custom/favicons/src/ /homelab/src/
COPY --from=npmconfig /root/.npmrc /root/.npmrc
RUN --mount=type=cache,target=/root/.npm,sharing=locked,id=favicons-nodejs-build-npmcache \
    NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error && \
    npm run build && \
    npm prune --production

### Healthcheck ###

FROM golang:1.26.4-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/http-healthcheck/main.go ./.shared/healthchecks/http-healthcheck/go.mod ./.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=favicons-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=favicons-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

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

FROM scratch AS homelab-dir
USER root
WORKDIR /homelab
COPY --from=nodejs-build /homelab/package.json /homelab/
COPY --from=nodejs-build /homelab/node_modules /homelab/node_modules
COPY --from=nodejs-build /homelab/dist /homelab/dist
COPY ./custom/favicons/icons /homelab/icons
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/
COPY --from=imagemagick-final /homelab/imagemagick /homelab/imagemagick

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
ENV HOMELAB_CONTAINER_NAME=favicons \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="/homelab/imagemagick/bin:${PATH}" \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=4s CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:8080/.health" ]
ENTRYPOINT [ "/nodejs/bin/node", "/homelab/dist/main.js" ]
