# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

### Build config ###

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS gitconfig
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
#     { curl --fail --silent 'https://gitcache-github.matejhome.com' || exit 0; } && \
#     git config --global 'url.https://gitcache-github.matejhome.com/.insteadOf' 'https://github.com/'

### Dependencies ###

FROM python:3.15.2-slim@sha256:63bb298d2b7b88f176f51b5189f54ce6535c997682ea70885d2132f5d473a8a5 AS gitman
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/dependencies/gitman/requirements.txt /homelab/
ENV PIP_DISABLE_PIP_VERSION_CHECK="1" \
    PIP_ROOT_USER_ACTION="ignore" \
    PYTHONDONTWRITEBYTECODE="1"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --quiet --no-compile --require-hashes --requirement './requirements.txt' --target './python-vendor'

### Supercronic ###

FROM python:3.15.2-slim@sha256:63bb298d2b7b88f176f51b5189f54ce6535c997682ea70885d2132f5d473a8a5 AS supercronic_gitman
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_supercronic_gitman_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_supercronic_gitman_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git retry >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/python-vendor /homelab/python-vendor
ENV GITMAN_CACHE="/root/.gitcache" \
    PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"
COPY ./docker-images/.shared/dependencies/supercronic/gitman.yml /homelab/
COPY --from=gitconfig /root/.gitconfig /root/.gitconfig
RUN --mount=type=cache,target=/root/.gitcache,sharing=locked,id=homelab_gitman_gitcache \
    retry --times=3 -- gitman install --quiet && \
    find '.' -type d -name '.git' -prune -exec rm -rf {} \;

FROM golang:1.27.4-trixie@sha256:430985542100b871e108ccc00e8dcc5eef08ca14ee5825e98ebf563d8ffec4ee AS supercronic_build
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_supercronic_build_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_supercronic_build_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=supercronic_gitman /homelab/gitman-repositories/supercronic/ ./supercronic/
ENV CGO_ENABLED="0"
WORKDIR /homelab/supercronic
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    go build -ldflags='-s -w -buildid=' -buildvcs=false && \
    strip --strip-all supercronic
WORKDIR /homelab
COPY ./docker-images/.shared/build-utils/validate-executable.sh /homelab/
RUN sh validate-executable.sh ./supercronic/supercronic

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

### App ###

FROM ghcr.io/seanmorley15/adventurelog-backend:v0.14.0@sha256:741a11ab16f53de555149f9750178873dd75b5ff1cb189fc6d55b577f26fbdc6 AS adventurelog_backend
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_apache_user_setup_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_apache_user_setup_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*
RUN sed -E 's~^command=/usr/sbin/cron .+~command=supercronic /homelab/crontab.cron~' <'/etc/supervisor/conf.d/supervisord.conf' | sponge '/etc/supervisor/conf.d/supervisord.conf'

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab
COPY ./docker-images/adventurelog/backend/crontab.cron /homelab/
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/
COPY --from=supercronic_build /homelab/supercronic/supercronic /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=adventurelog_backend /etc/supervisor/conf.d /fsroot/etc/supervisor/conf.d

### Final ###

FROM ghcr.io/seanmorley15/adventurelog-backend:v0.14.0@sha256:741a11ab16f53de555149f9750178873dd75b5ff1cb189fc6d55b577f26fbdc6 AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
RUN ln -sf /run/supervisord.pid /code/supervisord.pid && \
    ln -sf /run/supervisord.log /code/supervisord.log && \
    ln -sf /run/scheduler.log /code/scheduler.log && \
    chown -R homelab:homelab /code /var/log/nginx
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/etc/supervisor/conf.d /etc/supervisor/conf.d
ENV DEBUG="False" \
    DISABLE_REGISTRATION="True" \
    DJANGO_ADMIN_PASSWORD="" \
    DJANGO_ADMIN_USERNAME="admin" \
    EMAIL_BACKEND="email" \
    EMAIL_HOST="smtp4dev.matejhome.com" \
    EMAIL_PORT="25" \
    EMAIL_USE_SSL="False" \
    EMAIL_USE_TLS="False" \
    HOMELAB_CONTAINER_NAME="adventurelog" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PATH="/homelab/bin:${PATH}" \
    PGDATABASE="database" \
    PGHOST="postgis" \
    PGPASSWORD="" \
    PGUSER="postgres" \
    SECRET_KEY="" \
    TZ="Europe/Bratislava"
USER homelab
# Startup period a bit longer for initial migration - downloads stuff from github and sets up locations database
HEALTHCHECK --interval=10s --start-period=3m --timeout=2s --retries=1 CMD [ "healthcheck", "--url", "http://localhost:8000" ]
