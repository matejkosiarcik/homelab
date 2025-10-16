### Dependencies ###

FROM --platform=$BUILDPLATFORM debian:13.1-slim AS yq
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/dependencies/yq/requirements.txt ./
RUN python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

FROM --platform=$BUILDPLATFORM debian:13.1-slim AS jinja
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

FROM yq AS config-1
WORKDIR /homelab
COPY ./external/prometheus/data.yml ./
RUN yq . data.yml >data.json

FROM jinja AS config-2
WORKDIR /homelab
COPY --from=config-1 /homelab/data.json ./
COPY ./external/prometheus/prometheus.yml.j2 ./
RUN jinja2 prometheus.yml.j2 data.json --format json -o prometheus.yml

### Final ###

FROM debian:13.1-slim AS prefinal
WORKDIR /homelab
COPY ./external/prometheus/web.yml ./external/prometheus/entrypoint.sh /homelab/
COPY --from=config-2 ./homelab/prometheus.yml /homelab/prometheus.yml

FROM prom/prometheus:v3.7.0
ARG UID=1000
ARG GID=1000
USER root
RUN addgroup -g "$GID" homelab && \
    nologinshell='' && \
    if [ -e /sbin/nologin ]; then \
        nologinshell='/sbin/nologin' && \
    true; elif [ -e /usr/sbin/nologin ]; then \
        nologinshell='/usr/sbin/nologin' && \
    true; else \
        nologinshell='/bin/false' && \
    true; fi && \
    adduser -D -h /home/homelab -u "$UID" -G homelab -s "$nologinshell" homelab && \
    mkdir -p /home/homelab /homelab && \
    chown -R homelab:homelab /home/homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
ENV HOMELAB_CONTAINER_NAME=prometheus \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "wget -O /dev/null http://homelab-viewer:$PROMETHEUS_HOMELAB_VIEWER_PASSWORD@localhost:9090 || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
CMD []
USER homelab
