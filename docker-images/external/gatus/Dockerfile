# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_8: Ignore root user

FROM golang:1.24.4-alpine AS healthcheck-builder
WORKDIR /homelab
COPY ./.shared/healthcheck-placeholder/main.go ./.shared/healthcheck-placeholder/go.mod ./
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

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

FROM yq AS config-1
WORKDIR /homelab
COPY ./external/gatus/data.yml ./
RUN yq . data.yml >data.json

FROM jinja AS config-2
WORKDIR /homelab
COPY --from=config-1 /homelab/data.json ./
COPY ./external/gatus/config.yml.j2 ./
RUN jinja2 config.yml.j2 data.json --format json -o config.yml

### Final ###

FROM debian:12.11-slim AS prefinal
WORKDIR /homelab
COPY --from=config-2 /homelab/config.yml /homelab/config.yml
COPY --from=healthcheck-builder /homelab/healthcheck /homelab/healthcheck

FROM twinproduction/gatus:v5.19.0
COPY --from=prefinal /homelab/healthcheck /homelab/healthcheck
COPY --from=prefinal /homelab/config.yml /config/config.yaml
ENV GATUS_DELAY_START_SECONDS=0 \
    HOMELAB_CONTAINER_NAME=gatus \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava

# There isn't a way to do a real healthcheck inside this container, see: https://github.com/TwiN/gatus/issues/711
# So instead we just "fake" it and provide a dummy placeholder healthcheck program
HEALTHCHECK --interval=10s --start-period=20s --timeout=2s --retries=1 CMD [ "/homelab/healthcheck" ]
