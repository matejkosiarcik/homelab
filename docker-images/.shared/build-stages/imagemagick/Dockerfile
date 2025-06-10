# checkov:skip=CKV_DOCKER_3: User unnecessary
# checkov:skip=CKV_DOCKER_2: Healthcheck unnecessary

FROM debian:12.11-slim AS imagemagick
WORKDIR /homelab
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -q --yes --no-install-recommends \
        file imagemagick && \
    rm -rf /var/lib/apt/lists/*
