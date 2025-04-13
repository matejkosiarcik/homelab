# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM rnwood/smtp4dev:3.8.3
COPY ./external/smtp4dev/icons/favicon.ico /app/wwwroot/favicon.ico
ENV HOMELAB_CONTAINER_NAME=smtp4dev \
    HOMELAB_CONTAINER_VARIANT=default \
    ServerOptions__LockSettings=true \
    TZ=Europe/Bratislava \
    URLS=http://*:5000

# TODO: Enable TLS below
# ServerOptions__TlsMode=StartTls
# ServerOptions__SecureConnectionRequired=true
# ServerOptions__TlsCertificate=/homelab/certs/server.pem
# ServerOptions__AuthenticationRequired=true

# Note: curl/wget isn't available, so we have to resort to bash
HEALTHCHECK --interval=5s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "bash -c ':> /dev/tcp/localhost/5000' || exit 1" ]
