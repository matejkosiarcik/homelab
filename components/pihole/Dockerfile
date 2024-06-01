FROM pihole/pihole:2024.05.0
COPY custom-domains.txt /etc/pihole/custom.list
ENV DHCP_ACTIVE=false \
    FTLCONF_IGNORE_LOCALHOST=false \
    FTLCONF_PIHOLE_PTR=HOSTNAMEFQDN \
    FTLCONF_REPLY_WHEN_BUSY=BLOCK \
    IPv6=false \
    QUERY_LOGGING=false \
    TZ=Europe/Bratislava \
    WEBPASSWORD_FILE=/.homelab/webpassword.txt \
    WEBTHEME=default-darker
# Trailing underscore [in the name] is intentional
ENV PIHOLE_DNS_=8.8.8.8;1.1.1.1
HEALTHCHECK --interval=20s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost/admin || exit 1" ]
