# checkov:skip=CKV_DOCKER_8: Must run as root

FROM debian:13.2-slim AS gitconfig
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        ca-certificates curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/date.txt ./
RUN printf '' >/root/.gitconfig && \
    { curl --fail --silent https://git-cache-github.matejhome.com || exit 0; } && \
    git config --global url."https://git-cache-github.matejhome.com/".insteadOf "https://github.com/"

FROM python:3.14.2-slim AS samba-exporter-gitman
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/dependencies/gitman/requirements.txt ./
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./external/samba/prometheus-exporter/gitman.yml ./
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
COPY ./.shared/build-utils/validate-executable.sh ./
RUN sh validate-executable.sh ./samba_exporter/bin/samba_exporter && \
    sh validate-executable.sh ./samba_exporter/bin/samba_statusd

FROM debian:13.2-slim AS prefinal
USER root
WORKDIR /homelab
COPY ./external/samba/config ./config
COPY ./external/samba/entrypoint.sh ./
COPY --from=samba-exporter-build /homelab/samba_exporter/bin ./bin

FROM debian:13.2-slim
USER root
WORKDIR /homelab
ARG GID=1000
ARG UID=1000
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends --no-install-suggests \
        gnutls-bin samba && \
    rm -rf /var/lib/apt/lists/* && \
    if [ "$(getent group "$GID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
        groupadd --gid "$GID" homelab && \
    true; else \
        oldgroupname="$(getent group "$GID" | cut -d: -f1)" && \
        groupmod --new-name homelab "$oldgroupname" && \
    true; fi && \
    nologinshell='' && \
    if [ -e /sbin/nologin ]; then \
        nologinshell='/sbin/nologin' && \
    true; elif [ -e /usr/sbin/nologin ]; then \
        nologinshell='/usr/sbin/nologin' && \
    true; else \
        nologinshell='/bin/false' && \
    true; fi && \
    if [ "$(getent passwd "$UID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
        useradd --no-log-init --home /home/homelab --uid "$UID" --gid "$GID" --shell "$nologinshell" homelab && \
    true; else \
        oldusername="$(getent passwd "$UID" | cut -d: -f1)" && \
        usermod --move-home --home /home/homelab --uid "$UID" --gid "$GID" --shell "$nologinshell" --login homelab "$oldusername" && \
    true; fi && \
    mkdir -p /home/homelab /homelab && \
    chown -R homelab:homelab /home/homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
ENV HOMELAB_CONTAINER_NAME=samba \
    HOMELAB_CONTAINER_VARIANT=default \
    SAMBA_GROUP=homelab \
    SAMBA_USERNAME=homelab \
    TZ=Europe/Bratislava
# USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "bash -c ':> /dev/tcp/localhost/139' || exit 1" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
