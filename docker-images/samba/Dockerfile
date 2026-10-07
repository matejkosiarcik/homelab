# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest
# checkov:skip=CKV_DOCKER_8: Must run as root

## Miscellaneous ##

FROM debian:13.7-slim AS empty_dir
USER root
RUN mkdir /empty

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

FROM golang:1.27.1-trixie AS envsubst_build
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
    envsubst_version="$(cat /homelab/go.mod | grep "github.com/a8m/envsubst" | cut -d ' ' -f 3)" && \
    go install -ldflags='-s -w -buildid=' -buildvcs=false "github.com/a8m/envsubst/cmd/envsubst@${envsubst_version}" && \
    strip --strip-all /go/bin/envsubst
COPY ./docker-images/.shared/build-utils/validate-executable.sh /homelab/
RUN sh validate-executable.sh /go/bin/envsubst

FROM python:3.14.8-slim AS gitman
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/dependencies/gitman/requirements.txt /homelab/
ENV PIP_DISABLE_PIP_VERSION_CHECK="1" \
    PIP_ROOT_USER_ACTION="ignore" \
    PYTHONDONTWRITEBYTECODE="1"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=homelab_python_pipcache \
    python3 -m pip install --no-compile --requirement './requirements.txt' --target './python-vendor' --quiet

### Samba exporter ###

FROM python:3.14.8-slim AS samba_exporter_gitman
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_samba_prometheus_exporter_gitman_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_samba_prometheus_exporter_gitman_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        git retry >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/python-vendor /homelab/python-vendor
ENV GITMAN_CACHE="/root/.gitcache" \
    PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"
COPY ./docker-images/samba/prometheus-exporter/gitman.yml /homelab/
COPY --from=gitconfig /root/.gitconfig /root/.gitconfig
RUN --mount=type=cache,target=/root/.gitcache,sharing=locked,id=homelab_gitman_gitcache \
    retry --times=3 -- gitman install --quiet

FROM golang:1.27.1-trixie AS samba_exporter_build
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_samba_prometheus_exporter_build_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_samba_prometheus_exporter_build_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        binutils file git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=samba_exporter_gitman /homelab/gitman-repositories/samba_exporter/ ./samba_exporter/
ENV CGO_ENABLED="0"
WORKDIR /homelab/samba_exporter
RUN --mount=type=cache,target=/go/pkg/mod,sharing=shared,id=homelab_go_gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=shared,id=homelab_go_gobuildcache \
    --mount=type=cache,target=/root/.gitcache,sharing=locked,id=homelab_gitman_gitcache \
    ./build.sh build
WORKDIR /homelab
COPY ./docker-images/.shared/build-utils/validate-executable.sh /homelab/
RUN sh validate-executable.sh ./samba_exporter/bin/samba_exporter && \
    sh validate-executable.sh ./samba_exporter/bin/samba_statusd

### App config ###

FROM debian:13.7-slim AS app_config
USER root
WORKDIR /homelab
ARG HOMELAB_SAMBA_CONFIG=default
COPY ./docker-images/samba/config/${HOMELAB_SAMBA_CONFIG}.conf /homelab/smb.conf

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

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
COPY --from=app_config /homelab/smb.conf /homelab/
COPY ./docker-images/samba/entrypoint.sh /homelab/
COPY --from=samba_exporter_build /homelab/samba_exporter/bin /homelab/bin
COPY --from=envsubst_build /go/bin/envsubst /homelab/bin/
COPY --from=empty_dir /empty /homelab/logs/samba

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab

### Final ###

FROM debian:13.7-slim AS final
LABEL build.user=matejkosiarcik
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=homelab_samba_final_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=homelab_samba_final_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        samba >/dev/null && \
    rm -rf \
        /etc/apparmor.d/samba \
        /etc/apt \
        /etc/cron.d \
        /etc/cron.daily \
        /etc/cron.hourly \
        /etc/cron.monthly \
        /etc/cron.weekly \
        /etc/cron.yearly \
        /etc/init.d \
        /etc/logrotate.d \
        /etc/rc0.d \
        /etc/rc1.d \
        /etc/rc2.d \
        /etc/rc3.d \
        /etc/rc4.d \
        /etc/rc5.d \
        /etc/rc6.d \
        /etc/rcS.d \
        /etc/samba \
        /etc/systemd \
        /etc/ufw \
        /usr/lib/systemd \
        /usr/share/applications \
        /usr/share/bash-completion \
        /usr/share/bug \
        /usr/share/doc \
        /usr/share/fish \
        /usr/share/info \
        /usr/share/lintian \
        /usr/share/locale \
        /usr/share/man \
        /usr/share/menu \
        /usr/share/misc \
        /usr/share/pixmaps \
        /usr/share/polkit-1 \
        /usr/share/samba/admx \
        /usr/share/tabset \
        /usr/share/terminfo \
        /usr/share/zsh \
        /var/lib/systemd \
        /var/lib/apt/lists/* && \
    rm -f \
        /usr/bin/dbwrap_tool \
        /usr/bin/dumpmscat \
        /usr/bin/mvxattr \
        /usr/bin/net \
        /usr/bin/nmblookup \
        /usr/bin/oLschema2ldif \
        /usr/bin/pdbedit \
        /usr/bin/profiles \
        /usr/bin/samba-log-parser \
        /usr/bin/samba-regedit \
        /usr/bin/sharesec \
        /usr/bin/smbcontrol \
        /usr/bin/winexe \
        /usr/libexec/samba/samba-log-parser \
        /usr/sbin/eventlogadm \
        /usr/sbin/nmbd \
        /usr/share/samba/is-configured \
        /usr/share/samba/update-apparmor-samba-profile
COPY --from=prefinal /etc/group /etc/passwd /etc/shadow /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME="samba" \
    HOMELAB_CONTAINER_VARIANT="default" \
    PATH="/homelab/bin:${PATH}" \
    SAMBA_GROUP="homelab" \
    SAMBA_USERNAME="homelab" \
    TZ="Europe/Bratislava"
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "bash -c ':> /dev/tcp/localhost/139' || exit 1" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
