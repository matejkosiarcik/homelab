# checkov:skip=CKV_DOCKER_3: no need for explicit user

FROM linuxserver/unifi-network-application:8.3.32
ENV FILE__MONGO_PASS=/.homelab/database-password.txt \
    MONGO_DBNAME=database \
    MONGO_PORT=27017 \
    MONGO_USER=mongo \
    PGID=1000 \
    PUID=1000
# checkov:skip=CKV_SECRET_6: false positive in timezone
ENV TZ=Europe/Bratislava

# Following variables are recommended:
# - MEM_LIMIT=1024 # optional
# - MEM_STARTUP=1024 # optional
# - MONGO_TLS= # optional
# - MONGO_AUTHSOURCE= # optional

HEALTHCHECK --interval=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "if [ \"$(curl --insecure https://localhost:8443/status | jq .meta.up)\" = 'true' ]; then exit 0; else exit 1; fi" ]
