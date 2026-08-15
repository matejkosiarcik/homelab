# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest
# checkov:skip=CKV_DOCKER_8: Must run as root initially, but we switch to non-root user in entrypoint

### Dependencies ###

FROM debian:13.6-slim AS yq
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=gatus-dependency-yq-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=gatus-dependency-yq-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/yq/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked,id=gatus-dependency-yq-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet --resume-retries 1
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

FROM debian:13.6-slim AS jinja
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=gatus-dependency-jinja-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=gatus-dependency-jinja-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/jinja/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked,id=gatus-dependency-jinja-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet --resume-retries 1
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

### Build config ###

FROM debian:13.6-slim AS npmconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=data-optimizer-npmconfig-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=data-optimizer-npmconfig-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/anticache.txt /homelab/
RUN printf '' >/root/.npmrc && \
    { curl --fail --silent https://npm-cache.matejhome.com || exit 0; } && \
    npm config set proxy https://npm-cache.matejhome.com && \
    npm config set https-proxy https://npm-cache.matejhome.com

### App config ###

FROM yq AS apache-htaccess-config-1
USER root
WORKDIR /homelab
ARG HOMELAB_APP_TYPE=placeholder
COPY ./docker-compose/${HOMELAB_APP_TYPE}/config.yml /homelab/data.yml
RUN yq . data.yml >data.json

FROM jinja AS htaccess-config-2
USER root
WORKDIR /homelab
COPY --from=apache-htaccess-config-1 /homelab/data.json /homelab/
COPY ./docker-images/apache/htaccess/.htaccess-extra.j2 /homelab/
RUN jinja2 ./.htaccess-extra.j2 ./data.json --format json -o ./.htaccess-extra

FROM debian:13.6-slim AS htaccess-config-3
USER root
WORKDIR /homelab
COPY --from=htaccess-config-2 /homelab/.htaccess-extra /homelab/
COPY ./docker-images/apache/htaccess/.htaccess /homelab/
RUN sed -e '/## INSERT_EXTRA_REDIRECTS ##/{' -e 'r /homelab/.htaccess-extra' -e 'd'  -e '}' </homelab/.htaccess >/homelab/.htaccess-final && \
    mv /homelab/.htaccess-final /homelab/.htaccess

FROM jinja AS apache-config-2
USER root
WORKDIR /homelab
COPY --from=apache-htaccess-config-1 /homelab/data.json /homelab/
COPY ./docker-images/apache/apache.conf-extra.j2 /homelab/
RUN jinja2 ./apache.conf-extra.j2 ./data.json --format json -o ./apache.conf-extra

FROM debian:13.6-slim AS apache-config-3
USER root
WORKDIR /homelab
COPY --from=apache-config-2 /homelab/apache.conf-extra /homelab/
COPY ./docker-images/apache/apache.conf /homelab/
RUN sed -e '/## INSERT_EXTRA_REVERSE_PROXY ##/{' -e 'r /homelab/apache.conf-extra' -e 'd'  -e '}' </homelab/apache.conf >/homelab/apache.conf-final && \
    mv /homelab/apache.conf-final /homelab/apache.conf

### Error pages ###

FROM node:26.7.0-slim AS errors-build
USER root
WORKDIR /homelab
COPY --from=npmconfig /root/.npmrc /root/.npmrc
COPY ./docker-images/apache/errors/package-lock.json ./docker-images/apache/errors/package.json /homelab/
RUN --mount=type=cache,target=/root/.npm,sharing=locked,id=apache-errors-nodejs-build-npmcache \
    NODE_OPTIONS=--dns-result-order=ipv4first npm ci --unsafe-perm --no-progress --no-audit --no-fund --loglevel=error --prefer-offline
COPY ./docker-images/apache/errors/eleventy.config.js ./docker-images/apache/errors/postcss.config.js ./docker-images/apache/errors/terser.json ./docker-images/apache/errors/vite.config.ts ./docker-images/apache/errors/tsconfig.json /homelab/
COPY ./docker-images/apache/errors/src/ /homelab/src/
RUN npm run build && \
    npm prune --production

### Healthcheck ###

FROM golang:1.26.6-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=apache-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=apache-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Other ###

FROM debian:13.6-slim AS empty-dir
USER root
RUN mkdir /empty && \
    touch /empty.txt

### Users ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.6-slim AS user-setup
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apache-user-setup-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apache-user-setup-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh && \
    grep -E '^homelab:' </etc/group | sed 's~^homelab~www-data~' | sponge --append /etc/group && \
    grep -E '^homelab:' </etc/passwd | sed 's~^homelab~www-data~' | sponge --append /etc/passwd

### Prefinal ###

FROM scratch AS homelab-dir
USER root
WORKDIR /homelab
COPY --from=empty-dir /empty /homelab/certs
COPY --from=empty-dir /empty /homelab/logs
COPY --from=empty-dir /empty.txt /homelab/users/empty.htpasswd
COPY ./docker-images/apache/www /homelab/www
COPY --from=htaccess-config-3 /homelab/.htaccess /homelab/www/
COPY --from=errors-build /homelab/dist/out /homelab/www/.apache/errors
COPY ./docker-images/apache/entrypoint.sh /homelab/
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY --from=apache-config-3 /homelab/apache.conf /fsroot/apache.conf

### Final ###

FROM debian:13.6-slim
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apache-final-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apache-final-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        apache2 inotify-tools && \
    rm -rf /var/lib/apt/lists/* && \
    a2enmod auth_basic env headers http2 macro proxy proxy_http proxy_http2 proxy_wstunnel rewrite ssl status && \
    a2dismod -f alias && \
    rm -rf /etc/apache2/sites-enabled/* /var/www/html/*
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/apache.conf /etc/apache2/sites-enabled/apache.conf
WORKDIR /homelab
# For debugging enable following modules: dump_io log_forensic
# NOTE: "alias" module is disabled because it causes 403/404 errors, see also: https://serverfault.com/questions/153177/apache2-and-icons-path-behaving-differently
ENV HOMELAB_CONTAINER_NAME=apache \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "https://localhost/.apache", "--insecure", "--status", "401" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
