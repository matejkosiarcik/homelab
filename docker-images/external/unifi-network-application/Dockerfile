# checkov:skip=CKV_DOCKER_3: USER can't be set directly, because of the way linuxserver.io image works, but it should be active anyway because we set PUID/PGID

FROM linuxserver/unifi-network-application:9.3.45
RUN ln -s /config/data /usr/lib/unifi/data && \
    ln -s /config/logs /usr/lib/unifi/logs && \
    ln -s /run/unifi /usr/lib/unifi/run && \
    mkdir -p /homelab/defaults && \
    find /defaults -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/defaults/$(basename "$1")" "/homelab/defaults/$(basename "$1")"' - {} \; && \
    rm -rf /defaults
ARG UID=1999
ARG GID=1999
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" ) && \
    chown -R user:user /config /usr/lib/unifi
COPY --chown=user:user ./external/unifi-network-application/docker-entrypoint-extra.sh /homelab/
RUN head -n 1 /init >/homelab/docker-entrypoint-shebang.sh && \
    tail -n +2 /init >/homelab/docker-entrypoint-without-shebang.sh && \
    cat /homelab/docker-entrypoint-shebang.sh /homelab/docker-entrypoint-extra.sh /homelab/docker-entrypoint-without-shebang.sh >/init
ENV FILE__MONGO_PASS=/homelab/mongodb-password.txt \
    HOMELAB_CONTAINER_NAME=unifi-controller \
    HOMELAB_CONTAINER_VARIANT=default \
    MEM_LIMIT=2048 \
    MEM_STARTUP=2048 \
    MONGO_AUTHSOURCE=admin \
    MONGO_DBNAME=unifi \
    MONGO_PORT=27017 \
    MONGO_TLS= \
    MONGO_USER=unifi \
    PGID=$GID \
    PUID=$UID
# checkov:skip=CKV_SECRET_6: false positive in timezone
ENV TZ=Europe/Bratislava

HEALTHCHECK --interval=10s --start-period=360s --timeout=2s --retries=1 CMD [ "sh", "-c", "https_port=\"$(grep 'unifi.https.port' </defaults/system.properties | sed -E 's~^.+=~~')\" && if [ \"$(curl --insecure https://localhost:$https_port/status | jq .meta.up)\" = 'true' ]; then exit 0; else exit 1; fi" ]
