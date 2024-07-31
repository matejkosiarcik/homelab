# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM rnwood/smtp4dev:3.3.3
COPY ./external/smtp4dev/favicon.ico /app/wwwroot/favicon.ico
ENV ASPNETCORE_HTTP_PORTS=80 \
    ServerOptions__LockSettings=true \
    TZ=Europe/Bratislava

# TODO: Enable TLS below
# ServerOptions__TlsMode=StartTls
# ServerOptions__SecureConnectionRequired=true
# ServerOptions__TlsCertificate=/.homelab/certs/server.pem
# ServerOptions__AuthenticationRequired=true

# Note: curl/wget isn't available, so we have to resort to bash
HEALTHCHECK --interval=20s --timeout=2s --retries=1 CMD [ "sh", "-c", "timeout 1s bash -c ':> /dev/tcp/localhost/80'" ]
