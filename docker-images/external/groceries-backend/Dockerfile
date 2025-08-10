# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM ghcr.io/davideshay/groceries-server:1.1.9
COPY ./external/groceries-backend/healthcheck.js /homelab/healthcheck.js
ENV COUCHDB_USER=admin \
    HOMELAB_CONTAINER_NAME=groceries-backend \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava \
    ENABLE_SCHEDULING=1 \
    RESOLVE_CONFLICTS_FREQUENCY_MINUTES=5 \
    EXPIRE_JWT_FREQUENCY_MINUTES=60 \
    DISABLE_ACCOUNT_CREATION=0 \
    ACCESS_TOKEN_EXPIRES=12h \
    REFRESH_TOKEN_EXPIRES=30d \
    GROCERY_API_PORT=3333 \
    SMTP_HOST=smtp4dev.matejhome.com \
    SMTP_PORT=25 \
    SMTP_FROM=system@placeholder.matejhome.com \
    COUCHDB_DATABASE=groceries \
    COUCHDB_ADMIN_USER=admin \
    COUCHDB_INTERNAL_URL=http://couchdb:5984 \
    COUCHDB_URL=https://placeholder.matejhome.com/couchdb \
    GROCERY_URL=https://placeholder.matejhome.com \
    GROCERY_API_URL=https://placeholder.matejhome.com/api \
    SMTP_USER=sender
HEALTHCHECK --interval=10s --start-period=60s --timeout=5s --retries=1 CMD [ "sh", "-c", "node /homelab/healthcheck.js || exit 1" ]
