# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM pihole/pihole:2025.03.0
COPY ./external/pihole/adlists-default.txt ./external/pihole/domains-blacklist.txt ./external/pihole/domains-whitelist.txt ./external/pihole/setup.sh /homelab/
ENV DHCP_ACTIVE=false \
    FTLCONF_IGNORE_LOCALHOST=false \
    FTLCONF_PIHOLE_PTR=HOSTNAMEFQDN \
    FTLCONF_REPLY_WHEN_BUSY=BLOCK \
    HOMELAB_CONTAINER_NAME=pihole \
    HOMELAB_CONTAINER_VARIANT=default \
    IPv6=false \
    PIHOLE_DNS_=1.1.1.1;8.8.8.8 \
    QUERY_LOGGING=false \
    TZ=Europe/Bratislava \
    WEBPASSWORD_FILE=/homelab/pihole-password.txt \
    WEBTHEME=default-darker
# Trailing underscore for "PIHOLE_DNS_" is intentional
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost/admin || exit 1" ]
