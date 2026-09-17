# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

### Dependencies ###

FROM debian:13.6-slim AS yq
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=yq_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=yq_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/yq/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION="ignore"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=python_pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet --resume-retries 1
ENV PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"

FROM debian:13.6-slim AS jinja
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=jinja_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=jinja_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/jinja/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION="ignore"
RUN --mount=type=cache,target=/root/.cache/pip,sharing=shared,id=python_pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet --resume-retries 1
ENV PATH="/homelab/python-vendor/bin:${PATH}" \
    PYTHONPATH="/homelab/python-vendor"

### App config ###

FROM debian:13.6-slim AS config_1
USER root
WORKDIR /homelab
ARG HOMELAB_APP_EXTERNAL_DOMAIN=placeholder.example.com
ARG HOMELAB_APP_EXTERNAL_IP=127.0.0.1
ARG HOMELAB_APP_EXTERNAL_URL=https://placeholder.example.com
ARG HOMELAB_APP_FULLNAME=placeholder
ARG HOMELAB_APP_SHORTNAME=placeholder
ARG HOMELAB_APP_TYPE=placeholder
ARG HOMELAB_ENV=dev
RUN printf 'env:\n' >>data.yml && \
    printf '  HOMELAB_APP_EXTERNAL_DOMAIN: %s\n' "${HOMELAB_APP_EXTERNAL_DOMAIN}" >>data.yml && \
    printf '  HOMELAB_APP_EXTERNAL_IP: %s\n' "${HOMELAB_APP_EXTERNAL_IP}" >>data.yml && \
    printf '  HOMELAB_APP_EXTERNAL_URL: %s\n' "${HOMELAB_APP_EXTERNAL_URL}" >>data.yml && \
    printf '  HOMELAB_APP_FULLNAME: %s\n' "${HOMELAB_APP_FULLNAME}" >>data.yml && \
    printf '  HOMELAB_APP_SHORTNAME: %s\n' "${HOMELAB_APP_SHORTNAME}" >>data.yml && \
    printf '  HOMELAB_APP_TYPE: %s\n' "${HOMELAB_APP_TYPE}" >>data.yml && \
    printf '  HOMELAB_ENV: %s\n' "${HOMELAB_ENV}" >>data.yml

FROM yq AS config_2
USER root
WORKDIR /homelab
COPY --from=config_1 /homelab/data.yml /homelab/
RUN yq . data.yml >data.json

FROM jinja AS config_3
USER root
WORKDIR /homelab
COPY --from=config_2 /homelab/data.json /homelab/
COPY ./docker-images/unbound/app/unbound.conf.j2 /homelab/
RUN jinja2 unbound.conf.j2 data.json --format json -o unbound.conf

FROM debian:13.6-slim AS config_4
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=unbound_config_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=unbound_config_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=config_3 /homelab/unbound.conf /homelab/
RUN cat -s unbound.conf | sponge unbound.conf

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user_setup_base

FROM debian:13.6-slim AS user_setup
USER root
WORKDIR /homelab
COPY --from=user_setup_base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh

### Prefinal ###

FROM scratch AS homelab_dir
WORKDIR /homelab
COPY ./docker-images/unbound/app/entrypoint.sh /homelab/
COPY --from=config_4 /homelab/unbound.conf /homelab/

FROM scratch AS prefinal
COPY --from=user_setup /etc/group /etc/passwd /etc/
COPY --from=user_setup /home/homelab /home/homelab
COPY --from=homelab_dir /homelab /homelab

### Final ###

FROM debian:13.6-slim
USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=unbound_final_aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=unbound_final_aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        dnsutils libcap2-bin unbound >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    setcap 'cap_net_bind_service=+ep' "$(which unbound)"
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
WORKDIR /homelab
ENV HOMELAB_CONTAINER_NAME="unbound" \
    HOMELAB_CONTAINER_VARIANT="default" \
    TZ="Europe/Bratislava"
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/bin/sh", "-c", "dig @${HOMELAB_APP_EXTERNAL_IP} +short placeholder.matejhome.com || exit 1" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
