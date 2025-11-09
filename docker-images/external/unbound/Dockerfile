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

FROM --platform=$BUILDPLATFORM debian:13.1-slim AS config-1
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

FROM --platform=$BUILDPLATFORM yq AS config-2
WORKDIR /homelab
COPY --from=config-1 /homelab/data.yml ./
RUN yq . data.yml >data.json

FROM --platform=$BUILDPLATFORM jinja AS config-3
WORKDIR /homelab
COPY --from=config-2 /homelab/data.json ./
COPY ./external/unbound/unbound.conf.j2 ./
RUN jinja2 unbound.conf.j2 data.json --format json -o unbound.conf

FROM --platform=$BUILDPLATFORM debian:13.1-slim AS config-4
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        moreutils >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY --from=config-3 /homelab/unbound.conf ./
RUN cat -s unbound.conf | sponge unbound.conf

# ### Final ###

FROM --platform=$BUILDPLATFORM debian:13.1-slim AS prefinal
WORKDIR /homelab
COPY ./external/unbound/entrypoint.sh ./
COPY --from=config-4 /homelab/unbound.conf ./

FROM debian:13.1-slim
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        dnsutils libcap2-bin unbound >/dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    setcap 'cap_net_bind_service=+ep' "$(which unbound)"
ARG UID=1000
ARG GID=1000
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
WORKDIR /homelab
COPY --from=prefinal --chown=homelab:homelab /homelab/ ./
ENV HOMELAB_CONTAINER_NAME=unbound \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
USER homelab
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "dig @$HOMELAB_APP_EXTERNAL_IP +short placeholder.matejhome.com || exit 1" ]
ENTRYPOINT [ "/bin/sh", "/homelab/entrypoint.sh" ]
