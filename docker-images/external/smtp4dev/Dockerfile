FROM rnwood/smtp4dev:3.10.1
ARG UID=1000
ARG GID=1000
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" )
COPY --chown=user:user ./external/smtp4dev/icons/favicon.ico ./external/smtp4dev/icons/favicon.png /app/wwwroot/
ENV HOMELAB_CONTAINER_NAME=smtp4dev \
    HOMELAB_CONTAINER_VARIANT=default \
    ServerOptions__LockSettings=true \
    ServerOptions__Users__0__DefaultMailbox=Default \
    ServerOptions__Users__0__Username=admin \
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
USER user
