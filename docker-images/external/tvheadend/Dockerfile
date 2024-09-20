# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest

# hadolint ignore=DL3007

FROM python:3.12.6-slim AS tvhadmin-js-gitman
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends \
        git >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./.dependencies/gitman/requirements.txt ./
RUN python3 -m pip install --requirement requirements.txt --target python-vendor --quiet
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor
COPY ./.dependencies/tvhadmin-js/gitman.yml ./
RUN gitman install --quiet

FROM linuxserver/tvheadend:latest
COPY --from=tvhadmin-js-gitman /homelab/gitman-repositories/TVHadmin-JS/ /usr/share/tvheadend/src/webui/static/TVHadmin-JS
ENV HOMELAB_CONTAINER_NAME=tvheadend \
    HOMELAB_CONTAINER_VARIANT=default \
    PUID=1000 \
    PGID=1000 \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=30s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:9981 || exit 1" ]
