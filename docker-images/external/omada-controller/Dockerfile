# checkov:skip=CKV_DOCKER_3: USER can't be set directly, but it should be used after container initialized
# checkov:skip=CKV_DOCKER_2: Healthcheck is built-in

FROM mbentley/omada-controller:5.15
ARG UID=1000
ARG GID=1000
RUN ( groupadd -g "$GID" omada || groupmod --new-name omada "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" omada || usermod --login omada "$(getent passwd "$UID" | cut -d: -f1)" )
ENV HOMELAB_CONTAINER_NAME=omadacontroller \
    HOMELAB_CONTAINER_VARIANT=default \
    PUID=$UID \
    PGID=$GID \
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
