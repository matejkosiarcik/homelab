# syntax=docker/dockerfile:1

### Dependencies ###

FROM debian:13.5-slim AS yq
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=unbound-dependency-yq-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=unbound-dependency-yq-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/dependencies/yq/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked,id=unbound-dependency-yq-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

FROM debian:13.5-slim AS jinja
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=unbound-dependency-jinja-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=unbound-dependency-jinja-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.shared/dependencies/jinja/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked,id=unbound-dependency-jinja-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

### App config ###

FROM debian:13.5-slim AS config-1
USER root
WORKDIR /homelab
ARG HOMELAB_APP_EXTERNAL_DOMAIN=unbound.example.com
ARG HOMELAB_APP_EXTERNAL_IP=127.0.0.1
ARG HOMELAB_APP_EXTERNAL_URL=https://unbound.example.com
ARG HOMELAB_APP_NAME=unbound-default
ARG HOMELAB_APP_TYPE=unbound
ARG HOMELAB_ENV=dev
RUN printf 'env:\n' >>data.yml && \
    printf '  HOMELAB_APP_EXTERNAL_DOMAIN: %s\n' "$HOMELAB_APP_EXTERNAL_DOMAIN" >>data.yml && \
    printf '  HOMELAB_APP_EXTERNAL_IP: %s\n' "$HOMELAB_APP_EXTERNAL_IP" >>data.yml && \
    printf '  HOMELAB_APP_EXTERNAL_URL: %s\n' "$HOMELAB_APP_EXTERNAL_URL" >>data.yml && \
    printf '  HOMELAB_APP_NAME: %s\n' "$HOMELAB_APP_NAME" >>data.yml && \
    printf '  HOMELAB_APP_TYPE: %s\n' "$HOMELAB_APP_TYPE" >>data.yml && \
    printf '  HOMELAB_ENV: %s\n' "$HOMELAB_ENV" >>data.yml

FROM yq AS config-2
USER root
WORKDIR /homelab
COPY --from=config-1 /homelab/data.yml /homelab/
RUN yq . data.yml >data.json

FROM jinja AS config-3
USER root
WORKDIR /homelab
COPY --from=config-2 /homelab/data.json /homelab/
COPY ./external/unbound/unbound.conf.j2 /homelab/
RUN jinja2 unbound.conf.j2 data.json --format json -o unbound.conf

FROM debian:13.5-slim AS config-4
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=unbound-config-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=unbound-config-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=config-3 /homelab/unbound.conf /homelab/
RUN cat -s unbound.conf | sponge unbound.conf

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.5-slim AS user-setup
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
COPY ./external/unbound/entrypoint.sh /homelab/
COPY --from=config-4 /homelab/unbound.conf /homelab/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

FROM debian:13.5-slim
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=unbound-final-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=unbound-final-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        dnsutils libcap2-bin unbound >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    setcap 'cap_net_bind_service=+ep' "$(which unbound)"
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME=unbound \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "dig @127.0.0.1 +short placeholder.matejhome.com || exit 1" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
