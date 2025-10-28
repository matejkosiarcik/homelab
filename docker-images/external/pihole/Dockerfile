# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM pihole/pihole:2025.10.2
RUN apk update --no-cache && \
    apk add --no-cache shadow
ARG UID=1000
ARG GID=1000
ARG SETUP_SCRIPT=default
COPY --chown=pihole:pihole ./external/pihole/custom-domains.txt /homelab/
COPY --chown=pihole:pihole ./external/pihole/setup-${SETUP_SCRIPT}.sh /homelab/setup.sh
ENV DHCP_ACTIVE=false \
    DNSMASQ_USER=root \
    FTLCONF_dns_domain=matejhome.com \
    FTLCONF_dns_domainNeeded=true \
    FTLCONF_dns_ignoreLocalhost=false \
    FTLCONF_dns_listeningMode=all \
    FTLCONF_dns_piholePTR=HOSTNAMEFQDN \
    FTLCONF_dns_rateLimit_count=9000 \
    FTLCONF_dns_replyWhenBusy=ALLOW \
    FTLCONF_dns_upstreams=1.1.1.1;8.8.8.8;9.9.9.9 \
    FTLCONF_misc_privacylevel=0 \
    FTLCONF_webserver_api_allow_destructive=false \
    FTLCONF_webserver_domain=pihole-placeholder \
    FTLCONF_webserver_interface_theme=default-darker \
    HOMELAB_CONTAINER_NAME=pihole \
    HOMELAB_CONTAINER_VARIANT=default \
    PIHOLE_GID=$GID \
    PIHOLE_UID=$UID \
    TZ=Europe/Bratislava
# TODO: Remove DNSMASQ_USER=root override above
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost/admin || exit 1" ]
