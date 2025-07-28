# checkov:skip=CKV_DOCKER_3: No need for explicit user
# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in

FROM mbentley/omada-controller:5.15
RUN groupadd -g 508 omada && \
    useradd -u 508 -g 508 -m omada
ENV HOMELAB_CONTAINER_NAME=omada-controller \
    HOMELAB_CONTAINER_VARIANT=default \
    PUID=508 \
    PGID=508 \
    PORT_APP_DISCOVERY=27001 \
    PORT_ADOPT_V1=29812 \
    PORT_UPGRADE_V1=29813 \
    PORT_MANAGER_V1=29811 \
    PORT_MANAGER_V2=29814 \
    PORT_DISCOVERY=29810 \
    PORT_TRANSFER_V2=29815 \
    PORT_RTTY=29816 \
    SHOW_SERVER_LOGS=false \
    SHOW_MONGODB_LOGS=false \
    SSL_CERT_NAME=tls.crt \
    SSL_KEY_NAME=tls.key \
    TZ=Europe/Bratislava
