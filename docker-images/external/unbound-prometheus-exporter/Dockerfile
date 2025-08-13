# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM python:3.13.6-slim AS gitman
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
COPY ./external/unbound-prometheus-exporter/gitman.yml ./
RUN gitman install --quiet && \
    find . -type d -name .git -prune -exec rm -rf {} \;

FROM golang:1.25.0-bookworm AS build
WORKDIR /homelab
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        binutils file >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gitman /homelab/gitman-repositories/unbound_exporter/ ./unbound_exporter/
ENV CGO_ENABLED=0
WORKDIR /homelab/unbound_exporter
RUN go build -ldflags='-s -w -buildid=' -buildvcs=false && \
    strip --strip-all unbound_exporter
WORKDIR /homelab
COPY ./.shared/build-utils/validate-executable.sh ./
RUN sh validate-executable.sh ./unbound_exporter/unbound_exporter

FROM debian:13.0-slim AS prefinal
WORKDIR /homelab
COPY ./external/unbound-prometheus-exporter/entrypoint.sh ./entrypoint.sh
COPY --from=build /homelab/unbound_exporter/unbound_exporter ./bin/

FROM debian:13.0-slim
WORKDIR /homelab
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        curl >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=prefinal /homelab/ ./
ENV HOMELAB_CONTAINER_NAME=unbound-prometheus-exporter \
    HOMELAB_CONTAINER_VARIANT=default \
    PATH="/homelab/bin:$PATH" \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:9167/metrics || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
