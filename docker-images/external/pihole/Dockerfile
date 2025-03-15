# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM pihole/pihole:2025.03.0
COPY ./external/pihole/custom-domains.txt ./external/pihole/setup.sh /homelab/
ENV DHCP_ACTIVE=false \
    FTLCONF_dns_ignoreLocalhost=false \
    FTLCONF_dns_listeningMode=all \
    FTLCONF_dns_piholePTR=HOSTNAMEFQDN \
    FTLCONF_dns_replyWhenBusy=ALLOW \
    FTLCONF_dns_upstreams=1.1.1.1;8.8.8.8 \
    FTLCONF_misc_privacylevel=0 \
    FTLCONF_webserver_interface_theme=default-darker \
    HOMELAB_CONTAINER_NAME=pihole \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost/admin || exit 1" ]
