# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM linuxserver/unifi-network-application:9.2.87
RUN ln -s /config/data /usr/lib/unifi/data && \
    ln -s /config/logs /usr/lib/unifi/logs && \
    ln -s /run/unifi /usr/lib/unifi/run
ENV FILE__MONGO_PASS=/homelab/mongodb-password.txt \
    HOMELAB_CONTAINER_NAME=unifi-controller \
    HOMELAB_CONTAINER_VARIANT=default \
    MEM_LIMIT=2048 \
    MEM_STARTUP=2048 \
    MONGO_DBNAME=unifi \
    MONGO_PORT=27017 \
    MONGO_TLS= \
    MONGO_USER=unifi \
    PGID=1000 \
    PUID=1000
# checkov:skip=CKV_SECRET_6: false positive in timezone
ENV TZ=Europe/Bratislava

# Following variables are recommended:
# MONGO_AUTHSOURCE=admin

HEALTHCHECK --interval=10s --start-period=360s --timeout=2s --retries=1 CMD [ "sh", "-c", "https_port=\"$(grep 'unifi.https.port' </defaults/system.properties | sed -E 's~^.+=~~')\" && if [ \"$(curl --insecure https://localhost:$https_port/status | jq .meta.up)\" = 'true' ]; then exit 0; else exit 1; fi" ]
