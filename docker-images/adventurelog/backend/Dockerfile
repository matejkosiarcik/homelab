# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Build config ###

FROM debian:13.6-slim AS gitconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=certbot-gitconfig-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=certbot-gitconfig-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/anticache.txt /homelab/
RUN printf '' >/root/.gitconfig && \
    { curl --fail --silent https://git-cache-github.matejhome.com || exit 0; } && \
    git config --global url."https://git-cache-github.matejhome.com/".insteadOf "https://github.com/"

### Dependencies ###

FROM python:3.14.7-slim AS gitman
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/dependencies/gitman/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked,id=certbot-gitman-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet --resume-retries 1

### Supercronic ###

FROM python:3.14.7-slim AS supercronic-gitman
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=certbot-supercronic-gitman-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=certbot-supercronic-gitman-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/python-vendor /homelab/python-vendor
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./docker-images/.shared/dependencies/supercronic/gitman.yml /homelab/
COPY --from=gitconfig /root/.gitconfig /root/.gitconfig
RUN --mount=type=cache,target=/root/.cache/git,sharing=locked,id=certbot-supercronic-gitman-gitcache \
    gitman install --quiet && \
    find . -type d -name .git -prune -exec rm -rf {} \;

FROM golang:1.27.0-trixie AS supercronic-build
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=certbot-supercronic-build-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=certbot-supercronic-build-aptlibcache \
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
COPY ./docker-images/.shared/build-utils/validate-executable.sh /homelab/
RUN sh validate-executable.sh ./supercronic/supercronic

### Healthcheck ###

FROM golang:1.27.0-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=adventurelog-backend-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=adventurelog-backend-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Users ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.6-slim AS user-setup
USER root
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### App ###

FROM ghcr.io/seanmorley15/adventurelog-backend:v0.13.0 AS adventurelog-backend
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=apache-user-setup-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apache-user-setup-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*
RUN sed -E 's~^command=/usr/sbin/cron .+~command=supercronic /homelab/crontab.cron~' <'/etc/supervisor/conf.d/supervisord.conf' | sponge '/etc/supervisor/conf.d/supervisord.conf'

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab
COPY ./docker-images/adventurelog/backend/crontab.cron /homelab/
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/
COPY --from=supercronic-build /homelab/supercronic/supercronic /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab
COPY --from=adventurelog-backend /etc/supervisor/conf.d /fsroot/etc/supervisor/conf.d

### Final ###

FROM ghcr.io/seanmorley15/adventurelog-backend:v0.13.0
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
RUN ln -sf /run/supervisord.pid /code/supervisord.pid && \
    ln -sf /run/supervisord.log /code/supervisord.log && \
    ln -sf /run/scheduler.log /code/scheduler.log && \
    chown -R homelab:homelab /code /var/log/nginx
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/etc/supervisor/conf.d /etc/supervisor/conf.d
ENV DEBUG=False \
    DISABLE_REGISTRATION=True \
    DJANGO_ADMIN_USERNAME=admin \
    EMAIL_BACKEND=email \
    EMAIL_HOST=smtp4dev.matejhome.com \
    EMAIL_PORT=25 \
    EMAIL_USE_SSL=False \
    EMAIL_USE_TLS=False \
    HOMELAB_CONTAINER_NAME=adventurelog \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="/homelab/bin:$PATH" \
    PGDATABASE=database \
    PGHOST=postgis \
    PGUSER=postgres \
    TZ=Europe/Bratislava
USER homelab
# Startup period a bit longer for initial migration - downloads stuff from github and sets up locations database
HEALTHCHECK --interval=10s --start-period=180s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:8000" ]
