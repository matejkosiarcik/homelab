# syntax=docker/dockerfile:1
# checkov:skip=CKV_DOCKER_7: Unfortunately there is no other useful tag other than :latest
# checkov:skip=CKV_DOCKER_8: Must run as root

### Dependencies ###

FROM debian:13.6-slim AS yq
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=pihole-dependency-yq-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=pihole-dependency-yq-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        jq python3 python3-pip >/dev/null && \
    rm -rf /var/lib/apt/lists/*
COPY ./docker-images/.shared/dependencies/yq/requirements.txt /homelab/
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked,id=gatus-dependency-yq-pipcache \
    python3 -m pip install --requirement requirements.txt --target python-vendor --quiet --resume-retries 1
ENV PATH="/homelab/python-vendor/bin:$PATH" \
    PYTHONPATH=/homelab/python-vendor

### Healthcheck ###

FROM golang:1.26.5-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./docker-images/.shared/healthchecks/http-healthcheck/main.go ./docker-images/.shared/healthchecks/http-healthcheck/go.mod ./docker-images/.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked,id=pihole-healthcheck-build-gomodcache \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked,id=pihole-healthcheck-build-gobuildcache \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### App config ###

FROM yq AS dns_entries
USER root
WORKDIR /homelab
COPY ./servers/ /homelab/servers/
COPY ./docker-images/pihole/parse-app-entry.sh /homelab/
COPY ./docker-images/pihole/extra-domains.txt /homelab/
RUN find '/homelab/servers' -path '/homelab/servers/*/docker-apps/*' -mindepth 3 -maxdepth 3 -type d -not -name '.*' -print0 | xargs -0 -I% sh '/homelab/parse-app-entry.sh' % '/homelab/app-domains.txt' && \
    cat '/homelab/app-domains.txt' '/homelab/extra-domains.txt' | sed -E 's~ *#.*$~~' | grep -Ev '^$' | sort --version-sort >'/homelab/custom-domains.txt'

### User setup ###

# hadolint ignore=DL3007
FROM gcr.io/distroless/static-debian13:latest AS user-setup-base

FROM debian:13.6-slim AS user-setup
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=pihole-user-setup-aptcache \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=pihole-user-setup-aptlibcache \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./docker-images/.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh && \
    grep -E '^homelab:' </etc/group | sed 's~^homelab~pihole~' | sponge --append /etc/group && \
    grep -E '^homelab:' </etc/passwd | sed 's~^homelab~pihole~' | sponge --append /etc/passwd

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab
ARG SETUP_SCRIPT=default
COPY ./docker-images/pihole/setup-${SETUP_SCRIPT}.sh /homelab/setup.sh
COPY --from=dns_entries /homelab/custom-domains.txt /homelab/
COPY --from=healthcheck-build /homelab/healthcheck /homelab/bin/

FROM scratch AS prefinal
COPY --from=user-setup /etc/group /etc/passwd /etc/
COPY --from=user-setup /home/homelab /home/homelab
COPY --from=homelab-dir /homelab /homelab

### Final ###

FROM pihole/pihole:2025.11.1
USER root
COPY --from=prefinal /etc/group /etc/passwd /etc/
COPY --from=prefinal --chown=homelab:homelab /homelab /homelab
COPY --from=prefinal --chown=homelab:homelab /home/homelab /home/homelab
ENV DHCP_ACTIVE=false \
    DNSMASQ_USER=root \
    FTLCONF_dns_blockTTL=600 \
    FTLCONF_dns_domain=matejhome.com \
    FTLCONF_dns_domainNeeded=true \
    FTLCONF_dns_ignoreLocalhost=false \
    FTLCONF_dns_listeningMode=all \
    FTLCONF_dns_piholePTR=HOSTNAMEFQDN \
    FTLCONF_dns_rateLimit_count=0 \
    FTLCONF_dns_rateLimit_interval=0 \
    FTLCONF_dns_replyWhenBusy=BLOCK \
    FTLCONF_dns_upstreams=1.1.1.1;8.8.8.8;9.9.9.9 \
    FTLCONF_misc_dnsmasq_lines="local-ttl=600" \
    FTLCONF_misc_nice=-999 \
    FTLCONF_misc_privacylevel=0 \
    FTLCONF_webserver_api_allow_destructive=false \
    FTLCONF_webserver_domain=pihole-placeholder \
    FTLCONF_webserver_interface_theme=default-darker \
    HOMELAB_CONTAINER_NAME=pihole \
    HOMELAB_CONTAINER_VARIANT=default \
    PIHOLE_GID=$GID \
    PIHOLE_UID=$UID \
    TZ=Europe/Bratislava
# TODO: Investigate if it is possible to run as non-root
# TODO: Remove DNSMASQ_USER=root override above
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "/homelab/bin/healthcheck", "--url", "http://localhost/admin" ]
