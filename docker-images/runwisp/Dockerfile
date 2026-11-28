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

### Build dependencies ###

FROM python:3.15.2-slim@sha256:08a4c22c92b79ec821a7ad49768480039ee5b7accac3955228e75366e30abc8e AS gitman
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/dependencies/gitman/requirements.txt /homelab/
ENV PIP_DISABLE_PIP_VERSION_CHECK="1" \
    PIP_ROOT_USER_ACTION="ignore" \
    PYTHONDONTWRITEBYTECODE="1"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --quiet --no-compile --require-hashes --requirement './requirements.txt' --target './python-vendor'

FROM golang:1.27.4-trixie@sha256:430985542100b871e108ccc00e8dcc5eef08ca14ee5825e98ebf563d8ffec4ee AS envsubst_build
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
    strip --strip-all /go/bin/envsubst && \
    mkdir -p /homelab/bin && \
    mv /go/bin/envsubst /homelab/bin/
COPY ./docker-images/.shared/build-utils/validate-executable.sh /homelab/
RUN sh validate-executable.sh /homelab/bin/envsubst

### RunWisp ###

FROM python:3.15.2-slim@sha256:08a4c22c92b79ec821a7ad49768480039ee5b7accac3955228e75366e30abc8e AS runwisp_gitman
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
COPY ./docker-images/runwisp/gitman.yml /homelab/
RUN --mount=type=cache,target=/root/.gitcache,sharing=locked,id=homelab_gitman_gitcache \
    retry --times=3 -- gitman install --quiet && \
    find '.' -type d -name '.git' -prune -exec rm -rf {} \;

FROM golang:1.27.4-trixie@sha256:430985542100b871e108ccc00e8dcc5eef08ca14ee5825e98ebf563d8ffec4ee AS runwisp_build_tweak_paths
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_runwisp_build_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_runwisp_build_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        file libdigest-sha-perl moreutils >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=runwisp_gitman /homelab/gitman-repositories/runwisp/ ./runwisp/
COPY ./docker-images/runwisp/add-prefix.sh /homelab/
WORKDIR /homelab/runwisp
RUN sh '/homelab/add-prefix.sh'

FROM oven/bun:1.4.5-debian@sha256:3dddea58e1f8f2240eca906b023fedb944f9a8352515a35309fd0c879fe00aaa AS runwisp_build_frontend
USER root
WORKDIR /homelab
COPY --from=runwisp_build_tweak_paths /homelab/runwisp/ ./runwisp/
WORKDIR /homelab/runwisp
RUN --mount=type=cache,target=/root/.bun/install/cache,sharing=shared,id=homelab_runwisp_buncache \
    bun install --frozen-lockfile
WORKDIR /homelab/runwisp/apps/ui
RUN bunx --bun vite build

FROM golang:1.27.4-trixie@sha256:430985542100b871e108ccc00e8dcc5eef08ca14ee5825e98ebf563d8ffec4ee AS runwisp_build_backend
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

### Config ###

FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0 AS config
USER root
WORKDIR /homelab
COPY --from=envsubst_build /homelab/bin/envsubst /homelab/bin/
ENV PATH="/homelab/bin:${PATH}"
ARG HOMELAB_APP_EXTERNAL_URL="https://placeholder.matejhome.com" \
    HOMELAB_APP_SHORTNAME="placeholder" \
    HOMELAB_APP_TYPE="placeholder"
COPY ./docker-images/runwisp/config/${HOMELAB_APP_TYPE}.toml /homelab/input/runwisp.toml
RUN mkdir -p /homelab/config && \
    envsubst -no-digit -no-unset -no-empty -i '/homelab/input/runwisp.toml' -o '/homelab/config/runwisp.toml'

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
COPY --from=runwisp_build_backend /homelab/runwisp/apps/runwisp/runwisp /homelab/bin/
COPY --from=config /homelab/config/runwisp.toml /homelab/runwisp.toml
COPY ./docker-images/runwisp/entrypoint.sh /homelab/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab

### Final ###

FROM docker:29.10.1@sha256:fbbc96e0af32cdc190aff92ba97a1281a115351a723afe21af78879cc55126b0 AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
RUN apk add --no-cache tzdata
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
ENV DOCKER_HOST="tcp://docker-sockguard:2375" \
    HOMELAB_CONTAINER_NAME="runwisp" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PATH="/homelab/bin:${PATH}" \
    RUNWISP_CONFIG="/homelab/runwisp.toml" \
    RUNWISP_DATA="/data" \
    RUNWISP_HOST="0.0.0.0" \
    RUNWISP_LOG_FORMAT="text" \
    RUNWISP_PASSWORD="" \
    RUNWISP_PORT="8080" \
    RUNWISP_SOCKET="/homelab/tmpfs/runwisp.sock" \
    RUNWISP_TRUSTED_PROXIES="172.16.0.0/12" \
    RUNWISP_VIEWER_PASSWORD="" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=5s --retries=1 CMD [ "/homelab/bin/runwisp", "status" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
