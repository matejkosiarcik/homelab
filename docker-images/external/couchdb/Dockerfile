# checkov:skip=CKV_DOCKER_3: No need for explicit user

FROM couchdb:3.5.0
# printf '%s\n' "find /opt/couchdb/etc/local.d-tmp -mindepth 1 -maxdepth 1 -exec sh -c 'cp -R /opt/couchdb/etc/local.d-tmp/\$(basename \$1) /opt/couchdb/etc/local.d/\$(basename \$1)' - {} \;" >/homelab/docker-entrypoint-extra.sh && \
COPY ./external/couchdb/jwt.ini /opt/couchdb/etc/local.d/
RUN mkdir /homelab && \
    printf '%s\n' 'HMAC_KEY_BASE64="$(printf "%s" "$HMAC_KEY" | base64)" && cat /opt/couchdb/etc/local.d/jwt.ini | sed "s~#hmac-key#~$HMAC_KEY_BASE64~g" >/opt/couchdb/etc/local.d/jwt.ini2 && mv /opt/couchdb/etc/local.d/jwt.ini2 /opt/couchdb/etc/local.d/jwt.ini' >>/homelab/docker-entrypoint-extra.sh && \
    printf '%s\n' 'cat /opt/couchdb/etc/local.d/jwt.ini | sed "s~#uuid#~$UUID~g" >/opt/couchdb/etc/local.d/jwt.ini2 && mv /opt/couchdb/etc/local.d/jwt.ini2 /opt/couchdb/etc/local.d/jwt.ini' >>/homelab/docker-entrypoint-extra.sh && \
    head -n 1 /docker-entrypoint.sh >/homelab/docker-entrypoint-shebang.sh && \
    tail -n +2 /docker-entrypoint.sh >/homelab/docker-entrypoint-without-shebang.sh && \
    cat /homelab/docker-entrypoint-shebang.sh /homelab/docker-entrypoint-extra.sh /homelab/docker-entrypoint-without-shebang.sh >/docker-entrypoint.sh
ENV COUCHDB_USER=admin \
    HOMELAB_CONTAINER_NAME=couchdb \
    HOMELAB_CONTAINER_VARIANT=default \
    TZ=Europe/Bratislava
HEALTHCHECK --interval=10s --start-period=60s --timeout=2s --retries=1 CMD [ "sh", "-c", "curl --fail http://localhost:5984/_up || exit 1" ]
