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

### Dependencies ###

FROM python:3.15.2-slim AS gitman
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/dependencies/gitman/requirements.txt /homelab/
ENV PIP_DISABLE_PIP_VERSION_CHECK="1" \
    PIP_ROOT_USER_ACTION="ignore" \
    PYTHONDONTWRITEBYTECODE="1"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --no-compile --requirement './requirements.txt' --target './python-vendor' --quiet

### RunWisp ###

FROM python:3.15.2-slim AS runwisp_gitman
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_runwisp_gitman_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_runwisp_gitman_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git retry >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/python-vendor /homelab/python-vendor
ENV GITMAN_CACHE="/root/.gitcache" \
    PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"
COPY ./docker-images/renovatebot/runwisp/gitman.yml /homelab/
COPY --from=gitconfig /root/.gitconfig /root/.gitconfig
RUN --mount=type=cache,target=/root/.gitcache,sharing=locked,id=homelab_gitman_gitcache \
    retry --times=3 -- gitman install --quiet && \
    find '.' -type d -name '.git' -prune -exec rm -rf {} \;

FROM golang:1.27.3-trixie AS runwisp_build_tweak_paths
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_runwisp_build_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_runwisp_build_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        file libdigest-sha-perl moreutils >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=runwisp_gitman /homelab/gitman-repositories/runwisp/ ./runwisp/
COPY ./docker-images/renovatebot/runwisp/add-prefix.sh /homelab/
WORKDIR /homelab/runwisp
RUN sh '/homelab/add-prefix.sh'

FROM oven/bun:1.4.4-debian AS runwisp_build_frontend
USER root
WORKDIR /homelab
COPY --from=runwisp_build_tweak_paths /homelab/runwisp/ ./runwisp/
WORKDIR /homelab/runwisp
RUN --mount=type=cache,target=/root/.bun/install/cache,sharing=shared,id=homelab_runwisp_buncache \
    bun install --frozen-lockfile
WORKDIR /homelab/runwisp/apps/ui
RUN bunx --bun vite build

FROM golang:1.27.3-trixie AS runwisp_build_backend
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_runwisp_build_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_runwisp_build_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=runwisp_build_tweak_paths /homelab/runwisp/ ./runwisp/
COPY --from=runwisp_build_frontend /homelab/runwisp/apps/ui/build/ ./runwisp/apps/runwisp/internal/ui/dist/
COPY --from=runwisp_build_frontend /homelab/runwisp/apps/ui/build/ ./runwisp/apps/runwisp/internal/ui/dist/runwisp/
WORKDIR /homelab/runwisp/apps/runwisp
ENV CGO_ENABLED="0"
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    RELEASE=1 bash -o pipefail -c 'source ./scripts/metadata.sh && go build -ldflags "$(runner_ldflags) -buildid=" -buildvcs=false -o ./runwisp ./cmd/runwisp' && \
    strip --strip-all './runwisp'
WORKDIR /homelab
COPY ./docker-images/.shared/build-utils/validate-executable.sh /homelab/
RUN sh './validate-executable.sh' './runwisp/apps/runwisp/runwisp'

FROM scratch AS runwisp_final
COPY --from=runwisp_build_backend /homelab/runwisp/apps/runwisp/runwisp /usr/local/bin/runwisp

### Other ###

FROM debian:13.7-slim AS empty_dir
USER root
RUN mkdir /empty

FROM golang:1.27.3-trixie AS envsubst_build
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_envsubst_build_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_envsubst_build_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/envsubst/go.mod /homelab/
ENV CGO_ENABLED="0"
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    envsubst_version="$(grep "github.com/a8m/envsubst" <'/homelab/go.mod' | cut -d ' ' -f 3)" && \
    go install -ldflags='-s -w -buildid=' -buildvcs=false "github.com/a8m/envsubst/cmd/envsubst@${envsubst_version}" && \
    strip --strip-all /go/bin/envsubst
COPY ./docker-images/.shared/build-utils/validate-executable.sh /homelab/
RUN sh validate-executable.sh /go/bin/envsubst

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

### Prefinal ###

FROM scratch AS homelab_dir
USER root
WORKDIR /homelab
COPY --from=empty_dir /empty /homelab/logs
COPY ./docker-images/.shared/cron-utils/cron-wrapper.sh ./docker-images/renovatebot/entrypoint.sh ./docker-images/renovatebot/main.sh ./docker-images/renovatebot/runwisp/runwisp.toml /homelab/
COPY --from=runwisp_final /usr/local/bin/runwisp /homelab/bin/runwisp
COPY --from=envsubst_build /go/bin/envsubst /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY ./docker-images/renovatebot/config.js ./docker-images/renovatebot/test-config.js /usr/src/app/

### Final ###

FROM renovate/renovate:44.198.0-full AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
RUN chown -R homelab:homelab '/usr/src/app' '/home/ubuntu'
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /usr/src/app/config.js /usr/src/app/test-config.js /usr/src/app/
ENV HOMELAB_CONTAINER_NAME="renovatebot" \
    HOMELAB_CONTAINER_VARIANT="default" \
    HOMELAB_CRON_TIMEOUT="30m" \
    PATH="/homelab/bin:${PATH}" \
    RENOVATE_BASE_DIR="/tmp/renovate" \
    RUNWISP_CONFIG="/homelab/tmpfs/runwisp.toml" \
    RUNWISP_DATA="/runwisp" \
    RUNWISP_HOST="0.0.0.0" \
    RUNWISP_LOG_FORMAT="text" \
    RUNWISP_PORT="8080" \
    RUNWISP_SOCKET="/homelab/tmpfs/runwisp.sock" \
    RUNWISP_TRUSTED_PROXIES="172.16.0.0/12" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=1s --retries=1 CMD [ "/homelab/bin/runwisp", "status" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
