### Dependencies ###

FROM --platform=$BUILDPLATFORM debian:13.0-slim AS yq
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/dependencies/yq/requirements.txt ./
RUN python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

FROM --platform=$BUILDPLATFORM debian:13.0-slim AS jinja
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

FROM debian:13.0-slim AS prefinal
WORKDIR /homelab
COPY ./external/prometheus/web.yml ./external/prometheus/entrypoint.sh /homelab/
COPY --from=config-2 ./homelab/prometheus.yml /homelab/prometheus.yml

FROM prom/prometheus:v3.5.0
ARG UID=1000
ARG GID=1000
USER root
RUN ( addgroup -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( adduser -D -u "$UID" -G user user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab && \
    chown -R user:user /homelab
COPY --from=prefinal --chown=user:user /homelab /homelab
ENV HOMELAB_CONTAINER_NAME=prometheus \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "wget -O /dev/null http://admin:$PROMETHEUS_ADMIN_PASSWORD@localhost:9090 || exit 1" ]
ENTRYPOINT [ "sh", "/homelab/entrypoint.sh" ]
CMD []
USER user
