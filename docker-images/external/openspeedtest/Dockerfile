FROM openspeedtest/latest:v2.0.6
USER root
RUN mkdir -p /homelab/etc-nginx-conf.d && \
    find /etc/nginx/conf.d -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R "/etc/nginx/conf.d/$(basename "$1")" "/homelab/etc-nginx-conf.d/$(basename "$1")"' - {} \; && \
    rm -rf /etc/nginx/conf.d
COPY ./external/openspeedtest/entrypoint-extra.sh /homelab/
RUN mkdir -p /homelab && \
    head -n 1 /entrypoint.sh >/homelab/entrypoint-shebang.sh && \
    tail -n +2 /entrypoint.sh >/homelab/entrypoint-without-shebang.sh && \
    cat /homelab/entrypoint-shebang.sh /homelab/entrypoint-extra.sh /homelab/entrypoint-without-shebang.sh >/entrypoint.sh && \
    rm -rf /homelab/entrypoint-extra.sh
ARG GID=1000
ARG UID=1000
RUN apk update --no-cache && \
    apk add --no-cache shadow && \
    if [ "$(getent group "$GID" >/dev/null 2>&1; printf '%s' "$?")" -ne 0 ]; then \
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
    apk del --no-cache shadow && \
    mkdir -p /home/homelab /homelab && \
    chown -R homelab:homelab /home/homelab /homelab /etc/nginx && \
    chmod a+x "$(which crond)"
ENV ENABLE_LETSENCRYPT=False \
    HOMELAB_CONTAINER_NAME=openspeedtest \
    HOMELAB_CONTAINER_VARIANT=default \
    PGID=$GID \
    PUID=$UID \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=30s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:3000 || exit 1" ]
USER homelab
