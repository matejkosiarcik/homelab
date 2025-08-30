FROM ghcr.io/davideshay/groceries-server:1.1.9
ARG UID=999
ARG GID=999
RUN ( groupadd -g "$GID" user || groupmod --new-name user "$(getent group "$GID" | cut -d: -f1)" ) && \
    ( useradd -l -m -u "$UID" -g "$GID" user || usermod --login user "$(getent passwd "$UID" | cut -d: -f1)" )
COPY --chown=user:user ./external/groceries-backend/healthcheck.js /homelab/healthcheck.js
COPY --chown=user:user ./external/groceries-backend/globalItems.json /usr/app/data/globalItems.json
COPY --chown=user:user ./external/groceries-backend/categories.json /usr/app/data/categories.json
ENV ACCESS_TOKEN_EXPIRES=12h \
    COUCHDB_ADMIN_USER=admin \
    COUCHDB_DATABASE=groceries \
    COUCHDB_INTERNAL_URL=http://couchdb:5984 \
    COUCHDB_URL=https://placeholder.matejhome.com/couchdb \
    COUCHDB_USER=admin \
    DISABLE_ACCOUNT_CREATION=1 \
    ENABLE_SCHEDULING=1 \
    EXPIRE_JWT_FREQUENCY_MINUTES=60 \
    GROCERY_API_PORT=3333 \
    GROCERY_API_URL=https://placeholder.matejhome.com/api \
    GROCERY_URL=https://placeholder.matejhome.com \
    HOMELAB_CONTAINER_NAME=groceries-backend \
    HOMELAB_CONTAINER_VARIANT=default \
    REFRESH_TOKEN_EXPIRES=30d \
    RESOLVE_CONFLICTS_FREQUENCY_MINUTES=5 \
    SMTP_FROM=placeholder@matejhome.com \
    SMTP_HOST=smtp4dev.matejhome.com \
    SMTP_PORT=25 \
    SMTP_USER=sender \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=5s --retries=1 CMD [ "sh", "-c", "node /homelab/healthcheck.js || exit 1" ]
USER user
