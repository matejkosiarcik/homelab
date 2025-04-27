# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM linuxserver/unifi-network-application:9.0.114
ARG HOMELAB_BUILD_ENV=dev
# RUN grep -v -e 'unifi.http.port' -e 'unifi.https.port' -e 'portal.http.port' -e 'portal.https.port' </defaults/system.properties >/defaults/system.properties-2 && \
#     mv /defaults/system.properties-2 /defaults/system.properties && \
#     printf '\n# -- Custom properties start --\n\n' >>/defaults/system.properties && \
#     if [ "$HOMELAB_BUILD_ENV" = 'dev' ]; then \
#         printf 'unifi.http.port=%s\n' '8080' >>/defaults/system.properties && \
#         printf 'unifi.https.port=%s\n' '8443' >>/defaults/system.properties && \
#         printf 'portal.http.port=%s\n' '8081' >>/defaults/system.properties && \
#         printf 'portal.https.port=%s\n' '8444' >>/defaults/system.properties && \
#     true; elif [ "$HOMELAB_BUILD_ENV" = 'prod' ]; then \
#         printf 'unifi.http.port=%s\n' '80' >>/defaults/system.properties && \
#         printf 'unifi.https.port=%s\n' '443' >>/defaults/system.properties && \
#         printf 'portal.http.port=%s\n' '81' >>/defaults/system.properties && \
#         printf 'portal.https.port=%s\n' '444' >>/defaults/system.properties && \
#     true; else \
#         printf 'Unsupported HOMELAB_BUILD_ENV %s\n' "$HOMELAB_BUILD_ENV" && \
#         exit 1 && \
#     true; fi && \
#     printf '\n# -- Custom properties end --\n' >>/defaults/system.properties
ENV FILE__MONGO_PASS=/homelab/mongodb-password.txt \
    HOMELAB_CONTAINER_NAME=unifi-controller \
    HOMELAB_CONTAINER_VARIANT=default \
    MONGO_DBNAME=unifi \
    MONGO_PORT=27017 \
    MONGO_USER=unifi \
    PGID=1000 \
    PUID=1000
# checkov:skip=CKV_SECRET_6: false positive in timezone
ENV TZ=Europe/Bratislava

# Following variables are recommended:
# - MEM_LIMIT=1024 # optional
# - MEM_STARTUP=1024 # optional
# - MONGO_TLS= # optional
# - MONGO_AUTHSOURCE= # optional

HEALTHCHECK --interval=5s --start-period=360s --timeout=2s --retries=1 CMD [ "sh", "-c", "https_port=\"$(grep 'unifi.https.port' </defaults/system.properties | sed -E 's~^.+=~~')\" && if [ \"$(curl --insecure https://localhost:$https_port/status | jq .meta.up)\" = 'true' ]; then exit 0; else exit 1; fi" ]
