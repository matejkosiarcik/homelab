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
RUN jinja2 config.yml.j2 data.json --format json -o config.yml

### User setup ###

FROM twinproduction/gatus:v5.35.0 AS gatus
USER root

FROM debian:13.2-slim AS gatus-setcap
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        libcap2-bin >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=gatus /gatus /gatus
RUN setcap 'cap_net_raw+ep' /gatus

FROM debian:13.2-slim AS certificates
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        ca-certificates >/dev/null && \
    rm -rf /var/lib/apt/lists/*

FROM gcr.io/distroless/static-debian13 AS user-setup-base

FROM debian:13.2-slim AS user-setup
USER root
WORKDIR /homelab
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Final ###

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=certificates /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=config-2 /homelab/config.yml /homelab/
COPY --from=healthcheck-builder /homelab/healthcheck /homelab/bin/
COPY --from=gatus-setcap /gatus /homelab/bin/

FROM scratch
COPY --from=prefinal /etc /etc
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
ENV GATUS_CONFIG_PATH=/homelab/config.yml \
    GATUS_DELAY_START_SECONDS=0 \
    GATUS_LOG_LEVEL=INFO \
    HOMELAB_CONTAINER_NAME=gatus \
    HOMELAB_CONTAINER_VARIANT=default \
    PORT=8080 \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=20s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck" ]
ENTRYPOINT [ "/homelab/bin/gatus" ]
