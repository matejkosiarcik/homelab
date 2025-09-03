# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM python:3.13.7-slim AS samba-exporter-gitman
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/dependencies/gitman/requirements.txt ./
ENV PIP_ROOT_USER_ACTION=ignore
RUN python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./external/samba/prometheus-exporter/gitman.yml ./
RUN gitman install --quiet

FROM golang:1.25.1-bookworm AS samba-exporter-build
WORKDIR /homelab
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
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

FROM debian:13.0-slim AS prefinal
WORKDIR /homelab
COPY ./external/samba/config ./config
COPY ./external/samba/entrypoint.sh ./
COPY --from=samba-exporter-build /homelab/samba_exporter/bin ./bin

FROM debian:13.0-slim
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends \
        gnutls-bin samba && \
    rm -rf /var/lib/apt/lists/*
COPY --from=prefinal /homelab /homelab
ENV HOMELAB_CONTAINER_NAME=samba \
    HOMELAB_CONTAINER_VARIANT=default \
    SAMBA_USERNAME=admin \
    TZ=Europe/Bratislava
RUN groupadd 'admin-group' && \
    useradd -M -s /sbin/nologin 'admin' && \
    usermod -a -G 'admin-group' 'admin'
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "bash -c ':> /dev/tcp/localhost/139' || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
