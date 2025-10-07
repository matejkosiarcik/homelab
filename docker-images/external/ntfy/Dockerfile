FROM binwiederhier/ntfy:v2.14.0
ARG UID=1000
ARG GID=1000
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
    chown -R homelab:homelab /home/homelab /homelab
COPY --chown=homelab:homelab ./external/ntfy/setup.sh /homelab/
COPY --chown=homelab:homelab ./external/ntfy/config/server.yml /etc/ntfy/server.yml
ENV HOMELAB_CONTAINER_NAME=ntfy \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=5s --retries=1 CMD [ "sh", "-c", "wget -q --tries=1 http://localhost/v1/health -O - | grep -Eo '\"healthy\"\\s*:\\s*true' || exit 1" ]
ENTRYPOINT [ "ntfy" ]
CMD [ "serve" ]
USER homelab
