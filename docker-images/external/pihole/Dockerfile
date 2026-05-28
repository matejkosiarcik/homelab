# checkov:skip=CKV_DOCKER_8: Must run as root

### Healthcheck ###

FROM golang:1.25.5-alpine AS healthcheck-build
USER root
WORKDIR /homelab
COPY ./.shared/healthchecks/http-healthcheck/main.go ./.shared/healthchecks/http-healthcheck/go.mod ./.shared/healthchecks/http-healthcheck/go.sum /homelab/
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o healthcheck .

### User setup ###

FROM gcr.io/distroless/static-debian13 AS user-setup-base

FROM debian:13.2-slim AS user-setup
USER root
WORKDIR /homelab
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get install -qq --yes --no-install-recommends --no-install-suggests \
        moreutils && \
    rm -rf /var/lib/apt/lists/*
COPY --from=user-setup-base /etc/group /etc/passwd /etc/
ARG GID=1000
ARG UID=1000
COPY ./.shared/build-utils/create-user.sh /homelab/
RUN sh /homelab/create-user.sh && \
    cat /etc/group | grep -E '^homelab:' | sed 's~^homelab~pihole~' | sponge --append /etc/group && \
    cat /etc/passwd | grep -E '^homelab:' | sed 's~^homelab~pihole~' | sponge --append /etc/passwd

### Prefinal ###

FROM scratch AS homelab-dir
WORKDIR /homelab
ARG SETUP_SCRIPT=default
COPY --chown=pihole:pihole ./external/pihole/custom-domains.txt /homelab/
COPY --chown=pihole:pihole ./external/pihole/setup-${SETUP_SCRIPT}.sh /homelab/setup.sh
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
