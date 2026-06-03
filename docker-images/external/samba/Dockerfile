# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_8: Must run as root

### Build config ###

FROM debian:13.2-slim AS gitconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/anticache.txt /homelab/
RUN printf '' >/root/.gitconfig && \
    { curl --fail --silent https://git-cache-github.matejhome.com || exit 0; } && \
    git config --global url."https://git-cache-github.matejhome.com/".insteadOf "https://github.com/"

### Dependencies ###

FROM python:3.14.2-slim AS gitman
USER root
WORKDIR /homelab
COPY ./.shared/dependencies/gitman/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet

### Samba exporter ###

FROM python:3.14.2-slim AS samba-exporter-gitman
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/python-vendor /homelab/python-vendor
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./external/samba/prometheus-exporter/gitman.yml /homelab/
COPY --from=gitconfig /root/.gitconfig /root/.gitconfig
RUN --mount=type=cache,target=/root/.cache/git \
    gitman install --quiet

FROM golang:1.25.5-bookworm AS samba-exporter-build
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        binutils file git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=samba-exporter-gitman /root/.gitcache /root/.gitcache
COPY --from=samba-exporter-gitman /homelab/gitman-repositories/samba_exporter/ ./samba_exporter/
ENV CGO_ENABLED=0
WORKDIR /homelab/samba_exporter
RUN ./build.sh build
WORKDIR /homelab
COPY ./.shared/build-utils/validate-executable.sh /homelab/
RUN sh validate-executable.sh ./samba_exporter/bin/samba_exporter && \
    sh validate-executable.sh ./samba_exporter/bin/samba_statusd

### User setup ###

FROM gcr.io/distroless/static-debian13 AS user-setup-base

FROM debian:13.2-slim AS user-setup
USER root
WORKDIR /homelab
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab
COPY ./external/samba/config /homelab/config
COPY ./external/samba/entrypoint.sh /homelab/
COPY --from=samba-exporter-build /homelab/samba_exporter/bin /homelab/bin

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

FROM debian:13.2-slim
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        gnutls-bin samba && \
    rm -rf /var/lib/apt/lists/*
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME=samba \
    HOMELAB_CONTAINER_VARIANT=default \
    SAMBA_GROUP=homelab \
    SAMBA_USERNAME=homelab \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "bash -c ':> /dev/tcp/localhost/139' || exit 1" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
