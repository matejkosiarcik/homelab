FROM golang:1.25.1-alpine AS healthcheck-builder
WORKDIR /homelab
COPY ./.shared/healthcheck-placeholder/main.go ./.shared/healthcheck-placeholder/go.mod ./
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

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
COPY ./external/gatus/data.yml ./
RUN yq . data.yml >data.json

FROM jinja AS config-2
WORKDIR /homelab
COPY --from=config-1 /homelab/data.json ./
COPY ./external/gatus/config.yml.j2 ./
RUN jinja2 config.yml.j2 data.json --format json -o config.yml

### Final ###

FROM debian:13.1-slim AS prefinal
WORKDIR /homelab
COPY --from=config-2 /homelab/config.yml /homelab/config.yml
COPY --from=healthcheck-builder /homelab/healthcheck /homelab/healthcheck

FROM twinproduction/gatus:v5.24.2 AS gatus

FROM debian:13.1-slim
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        ca-certificates libcap2-bin >/dev/null && \
    rm -rf /var/lib/apt/lists/*
ARG UID=1000
ARG GID=1000
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    mkdir -p /homelab && \
    chown -R user:user /homelab
COPY --from=gatus --chown=user:user /gatus /gatus
RUN setcap 'cap_net_raw+ep' /gatus
COPY --from=prefinal --chown=user:user /homelab/healthcheck /homelab/healthcheck
COPY --from=prefinal --chown=user:user /homelab/config.yml /config/config.yaml
ENV GATUS_CONFIG_PATH="" \
    GATUS_DELAY_START_SECONDS=0 \
    GATUS_LOG_LEVEL=INFO \
    HOMELAB_CONTAINER_NAME=gatus \
    HOMELAB_CONTAINER_VARIANT=default \
    PORT=8080 \
    TZ=Europe/Bratislava
USER user

# There isn't a way to do a real healthcheck inside this container, see: https://github.com/TwiN/gatus/issues/711
# So instead we just "fake" it and provide a dummy placeholder healthcheck program
HEALTHCHECK --interval=10s --start-period=20s --timeout=2s --retries=1 CMD [ "/homelab/healthcheck" ]
ENTRYPOINT [ "/gatus" ]
