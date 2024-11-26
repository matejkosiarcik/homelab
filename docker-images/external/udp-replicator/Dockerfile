# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM python:3.13.0-slim AS udp-replicator-gitman
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.dependencies/gitman/requirements.txt ./
ENV PIP_ROOT_USER_ACTION=ignore
RUN python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./.dependencies/udp-replicator/gitman.yml ./
RUN gitman install --quiet

FROM golang:1.23.3-bookworm AS udp-replicator-build
WORKDIR /homelab
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=udp-replicator-gitman /homelab/gitman-repositories/udp-replicator/ ./udp-replicator/
ENV CGO_ENABLED=0
WORKDIR /homelab/udp-replicator
RUN go build -ldflags='-s -w -buildid=' -buildvcs=false && \
    strip --strip-all udp-replicator
WORKDIR /homelab
COPY ./.shared/build-utils/validate-executable.sh ./
RUN sh validate-executable.sh ./udp-replicator/udp-replicator

FROM debian:12.8-slim AS prefinal
WORKDIR /homelab
RUN mkdir -p ./certs ./logs
COPY --from=udp-replicator-build /homelab/udp-replicator/udp-replicator ./bin/

FROM debian:12.8-slim
WORKDIR /homelab
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        ca-certificates curl openssl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=prefinal /homelab/ ./
ENV HOMELAB_CONTAINER_NAME=certificate-manager \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="$PATH:/homelab/bin" \
    TZ=Europe/Bratislava
# HEALTHCHECK --interval=5s --start-period=60s --timeout=1s --retries=1 CMD [ "sh", "-c", "printf 'started\n' | cmp /homelab/.internal/status.txt /dev/stdin >/dev/null 2>&1 || exit 1" ]
# ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
ENTRYPOINT [ "/homelab/bin/udp-replicator", "--listen-ip=0.0.0.0", "--listen-port=53", "--forward=10.1.10.1:53", "--forward=10.1.10.3:53" ]
