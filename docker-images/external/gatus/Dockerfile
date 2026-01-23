FROM golang:1.25.5-alpine AS healthcheck-builder
USER root
WORKDIR /homelab
COPY ./external/gatus/healthcheck/main.go ./external/gatus/healthcheck/go.mod ./
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### Dependencies ###

FROM debian:13.2-slim AS yq
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/dependencies/yq/requirements.txt ./
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
COPY ./.shared/dependencies/jinja/requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

### Config ###

FROM yq AS config-1
USER root
WORKDIR /homelab
COPY ./external/gatus/data.yml ./
RUN yq . data.yml >data.json

FROM jinja AS config-2
USER root
WORKDIR /homelab
COPY --from=config-1 /homelab/data.json ./
COPY ./external/gatus/config.yml.j2 ./
RUN jinja2 config.yml.j2 data.json --format json -o config.yaml

### Final ###

FROM debian:13.2-slim AS prefinal
USER root
WORKDIR /homelab
COPY --from=config-2 /homelab/config.yaml /homelab/
COPY --from=healthcheck-builder /homelab/healthcheck /homelab/bin/

FROM twinproduction/gatus:v5.33.1 AS gatus
USER root

FROM debian:13.2-slim
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates libcap2-bin >/dev/null && \
    rm -rf /var/lib/apt/lists/*
ARG GID=1000
ARG UID=1000
RUN if [ "$(getent group "$GID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
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
COPY --from=gatus --chown=homelab:homelab /gatus /gatus
RUN setcap 'cap_net_raw+ep' /gatus
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
ENV GATUS_CONFIG_PATH="" \
    GATUS_DELAY_START_SECONDS=0 \
    GATUS_LOG_LEVEL=INFO \
    HOMELAB_CONTAINER_NAME=gatus \
    HOMELAB_CONTAINER_VARIANT=default \
    PORT=8080 \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=20s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck" ]
ENTRYPOINT [ "/gatus" ]
