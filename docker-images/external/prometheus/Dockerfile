# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_8: Ignore root user

### Dependencies ###

FROM --platform=$BUILDPLATFORM debian:12.11-slim AS yq
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/dependencies/yq/requirements.txt ./
RUN python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

FROM --platform=$BUILDPLATFORM debian:12.11-slim AS jinja
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/dependencies/jinja/requirements.txt ./
RUN python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

### Config ###

FROM yq as config-1
WORKDIR /homelab
COPY ./external/prometheus/data.yml ./
RUN yq . data.yml >data.json

FROM jinja as config-2
WORKDIR /homelab
COPY --from=config-1 /homelab/data.json ./
COPY ./external/prometheus/prometheus.yml.j2 ./
RUN jinja2 prometheus.yml.j2 data.json --format json -o prometheus.yml

### Final ###

FROM debian:12.11-slim AS prefinal
WORKDIR /homelab
COPY ./external/prometheus/web.yml ./external/prometheus/entrypoint.sh /etc/prometheus/
COPY --from=config-2 ./homelab/prometheus.yml /etc/prometheus/prometheus.yml

FROM prom/prometheus:v3.4.1
COPY --from=prefinal /etc/prometheus/web.yml /etc/prometheus/prometheus.yml /etc/prometheus/entrypoint.sh /etc/prometheus/
ENV HOMELAB_CONTAINER_NAME=prometheus \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "wget -O /dev/null http://admin:$PROMETHEUS_ADMIN_PASSWORD@localhost:9090 || exit 1" ]
# hadolint ignore=DL3002
USER root
ENTRYPOINT [ "sh", "/etc/prometheus/entrypoint.sh" ]
CMD []
