# checkov:skip=CKV_DOCKER_3: USER can't be set directly, because of the way linuxserver.io image works, but it should be active anyway because we set PUID/PGID

FROM linuxserver/unifi-network-application:9.4.19
RUN ln -s /config/data /usr/lib/unifi/data && \
    ln -s /config/logs /usr/lib/unifi/logs && \
    ln -s /run/unifi /usr/lib/unifi/run && \
    mkdir -p /homelab/defaults && \
    find /defaults -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/defaults/$(basename "$1")" "/homelab/defaults/$(basename "$1")"' - {} \; && \
    rm -rf /defaults
ARG UID=1000
ARG GID=1000
RUN if [ "$(getent group "$GID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
        groupadd --gid "$GID" homelab && \
    true; else \
        oldgroupname="$(getent group "$GID" | cut -d: -f1)" && \
        groupmod --new-name homelab "$oldgroupname" && \
    true; fi && \
    nologinshell='' && \
    if [ -e /sbin/nologin ]; then \
        nologinshell='/sbin/nologin' && \
    true; elif [ -e /usr/sbin/nologin ]; then \
        nologinshell='/usr/sbin/nologin' && \
    true; else \
        nologinshell='/bin/false' && \
    true; fi && \
    if [ "$(getent passwd "$UID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
        useradd --no-log-init --home /home/homelab --uid "$UID" --gid "$GID" --shell "$nologinshell" homelab && \
    true; else \
        oldusername="$(getent passwd "$UID" | cut -d: -f1)" && \
        usermod --move-home --home /home/homelab --uid "$UID" --gid "$GID" --shell "$nologinshell" --login homelab "$oldusername" && \
    true; fi && \
    mkdir -p /home/homelab /homelab && \
    chown -R homelab:homelab /home/homelab /homelab /usr/lib/unifi
COPY --chown=homelab:homelab ./external/unifi-network-application/entrypoint-extra.sh /homelab/
RUN head -n 1 /init >/homelab/entrypoint-shebang.sh && \
    tail -n +2 /init >/homelab/entrypoint-without-shebang.sh && \
    cat /homelab/entrypoint-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-without-shebang.sh >/init
ENV FILE__MONGO_PASS=/homelab/mongodb-password.txt \
    HOMELAB_CONTAINER_NAME=unificontroller \
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
