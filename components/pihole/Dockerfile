# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM pihole/pihole:2024.06.0
# COPY custom-domains.txt /etc/pihole/custom.list
ENV DHCP_ACTIVE=false \
    FTLCONF_IGNORE_LOCALHOST=false \
    FTLCONF_PIHOLE_PTR=HOSTNAMEFQDN \
    FTLCONF_REPLY_WHEN_BUSY=BLOCK \
    IPv6=false \
    PIHOLE_DNS_=1.1.1.1;4.2.2.1;8.8.8.8 \
    QUERY_LOGGING=false \
    TZ=Europe/Bratislava \
    WEBPASSWORD_FILE=/.homelab/webpassword.txt \
    WEBTHEME=default-darker
# Trailing underscore for "PIHOLE_DNS_" is intentional
HEALTHCHECK --interval=20s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost/admin || exit 1" ]
