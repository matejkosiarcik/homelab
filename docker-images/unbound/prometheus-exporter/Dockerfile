# syntax=docker/dockerfile:1

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
#     { curl --fail --silent 'https://gitcache-github.matejhome.com' || exit 0; } && \
#     git config --global 'url.https://gitcache-github.matejhome.com/.insteadOf' 'https://github.com/'

### Dependencies ###

FROM python:3.15.2-slim AS gitman
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/dependencies/gitman/requirements.txt /homelab/
ENV PIP_DISABLE_PIP_VERSION_CHECK="1" \
    PIP_ROOT_USER_ACTION="ignore" \
    PYTHONDONTWRITEBYTECODE="1"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --quiet --no-compile --require-hashes --requirement './requirements.txt' --target './python-vendor'

FROM python:3.15.2-slim AS unbound_prometheus_exporter_gitman
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_unbound_prometheus_exporter_gitman_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_unbound_prometheus_exporter_gitman_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git retry >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/python-vendor /homelab/python-vendor
ENV GITMAN_CACHE="/root/.gitcache" \
    PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"
COPY ./docker-images/unbound/prometheus-exporter/gitman.yml /homelab/
COPY --from=gitconfig /root/.gitconfig /root/.gitconfig
RUN --mount=type=cache,target=/root/.gitcache,sharing=locked,id=homelab_gitman_gitcache \
    retry --times=3 -- gitman install --quiet && \
    find '.' -type d -name '.git' -prune -exec rm -rf {} \;

### App ###

FROM golang:1.27.4-trixie AS unbound_prometheus_exporter_build
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_unbound_prometheus_exporter_build_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_unbound_prometheus_exporter_build_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=unbound_prometheus_exporter_gitman /homelab/gitman-repositories/unbound_exporter/ /homelab/unbound_exporter/
ENV CGO_ENABLED="0"
WORKDIR /homelab/unbound_exporter
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    go build -ldflags='-s -w -buildid=' -buildvcs=false && \
    strip --strip-all unbound_exporter
WORKDIR /homelab
COPY ./docker-images/.shared/build-utils/validate-executable.sh /homelab/
RUN sh validate-executable.sh ./unbound_exporter/unbound_exporter

### Healthcheck ###

FROM golang:1.27.4-alpine AS healthcheck_build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -o healthcheck .

### Other ###

FROM busybox:1.38.0-uclibc AS busybox
USER root
RUN mkdir -p '/fsroot/bin' && \
    cp '/bin/date' '/bin/sh' '/bin/sleep' '/bin/timeout' '/fsroot/bin/'

### User setup ###

FROM gcr.io/distroless/static-debian13:latest@sha256:1a64f46364620465ef9e9a8f5413757dfdf22695e050bbfd7303eeaf17a59383 AS user_setup_base

FROM debian:13.7-slim AS user_setup
USER root
WORKDIR /homelab
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh '/homelab/create-user.sh' && \
    pwconv && \
    passwd --lock homelab

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab
COPY ./docker-images/unbound/prometheus-exporter/entrypoint.sh /homelab/entrypoint.sh
COPY --from=unbound_prometheus_exporter_build /homelab/unbound_exporter/unbound_exporter /homelab/bin/
COPY --from=healthcheck_build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab
COPY --from=busybox /fsroot/bin/ /fsroot/bin/

### Final ###

FROM gcr.io/distroless/base-debian13:latest@sha256:ca90dc2333005edbc15bccbd7cd61c08ee0fd9dd1fa5ac68bc72778e6659ec5d AS final
LABEL build.user="matejkosiarcik" \
    dev.dozzle.icon="none"
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /fsroot/bin/ /bin/
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME="unbound-prometheus-exporter" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PATH="/homelab/bin:${PATH}" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost:9167/metrics" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
