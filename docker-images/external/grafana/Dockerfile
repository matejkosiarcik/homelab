# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM grafana/grafana-oss:12.0.2
ENV GF_PLUGINS_PREINSTALL= \
    GF_SECURITY_ADMIN_USER=admin \
    GF_SECURITY_COOKIE_SAMESITE=strict \
    GF_SECURITY_COOKIE_SECURE=true \
    GF_SECURITY_DISABLE_GRAVATAR=true \
    HOMELAB_CONTAINER_NAME=grafana \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:3000 || exit 1" ]
