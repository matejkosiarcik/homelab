### Dependencies ###

FROM debian:13.2-slim AS yq
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/dependencies/yq/requirements.txt /homelab/
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

FROM debian:13.2-slim AS jinja
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/dependencies/jinja/requirements.txt /homelab/
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

### Config ###

FROM yq AS config-1
USER root
WORKDIR /homelab
COPY ./external/prometheus/data.yml /homelab/
RUN yq . data.yml >data.json

FROM jinja AS config-2
USER root
WORKDIR /homelab
COPY --from=config-1 /homelab/data.json /homelab/
COPY ./external/prometheus/prometheus.yml.j2 /homelab/
RUN jinja2 prometheus.yml.j2 data.json --format json -o prometheus.yml

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
COPY ./external/prometheus/web.yml ./external/prometheus/entrypoint.sh /homelab/
COPY --from=config-2 ./homelab/prometheus.yml /homelab/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

FROM prom/prometheus:v3.8.1
USER root
ARG GID=1000
ARG UID=1000
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
ENV HOMELAB_CONTAINER_NAME=prometheus \
    HOMELAB_CONTAINER_VARIANT=default \
    PROMETHEUS__HOMELAB_VIEWER_USERNAME=homelab-viewer \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "wget -O /dev/null http://$PROMETHEUS__HOMELAB_VIEWER_USERNAME:$PROMETHEUS__HOMELAB_VIEWER_PASSWORD@localhost:9090 || exit 1" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
CMD []
