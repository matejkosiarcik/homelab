FROM rnwood/smtp4dev:3.10.3
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
    chown -R homelab:homelab /home/homelab /homelab
COPY --chown=homelab:homelab ./external/smtp4dev/icons/favicon.ico ./external/smtp4dev/icons/favicon.png /app/wwwroot/
ENV HOMELAB_CONTAINER_NAME=smtp4dev \
    HOMELAB_CONTAINER_VARIANT=default \
    ServerOptions__LockSettings=true \
    ServerOptions__Users__0__DefaultMailbox=Default \
    ServerOptions__Users__0__Username=matej \
    ServerOptions__Users__1__DefaultMailbox=Default \
    ServerOptions__Users__1__Username=homelab-viewer \
    ServerOptions__Users__2__DefaultMailbox=Default \
    ServerOptions__Users__2__Username=homelab-test \
    ServerOptions__WebAuthenticationRequired=true \
    TZ=Europe/Bratislava \
    URLS=http://*:5000

# TODO: Enable TLS below
# ServerOptions__TlsMode=StartTls
# ServerOptions__SecureConnectionRequired=true
# ServerOptions__TlsCertificate=/homelab/certs/server.pem
# ServerOptions__AuthenticationRequired=true

# Note: curl/wget isn't available, so we have to resort to bash
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "bash -c ':> /dev/tcp/localhost/5000' || exit 1" ]
USER homelab
